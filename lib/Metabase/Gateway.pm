package Metabase::Gateway;
use Moose;

use Metabase::Librarian;
use Data::GUID;

use Metabase::Fact;
use Metabase::User::Profile;

# XXX life becomes a lot easier if we say that fact classes MUST have 1-to-1 
# relationship with a .pm file. -- dagolden, 2009-03-31

has fact_classes => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  auto_deref => 1,
  required   => 1,
);

has approved_types => (
  is          =>  'ro',
  isa         =>  'ArrayRef[Str]',
  auto_deref  => 1,
  lazy        => 1,
  builder     => '_build_approved_types',
  init_arg    => undef,
);

has autocreate_profile => (
  is          => 'ro',
  isa         => 'Bool',
  default     => 0,
);

has librarian => (
  is       => 'ro',
  isa      => 'Metabase::Librarian',
  required => 1,
);

has secret_librarian => (
  is       => 'ro',
  isa      => 'Metabase::Librarian',
  required => 1,
);

# recurse report classes -- less to specify to new()
sub _build_approved_types {
  my ($self) = @_;
  my @queue = $self->fact_classes;
  my @approved;
  while ( my $class = shift @queue ) {
    push @approved, $class;
    # XXX $class->can('fact_classes') ?? -- dagolden, 2009-03-31
    push @queue, $class->fact_classes if $class->isa('Metabase::Report');
  }
  return [ map { $_->type } @approved ];
}

sub _validate_resource {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

sub __validate_submitter {
  my ($self, $submission) = @_;

  # generate fact objects for submitter profile and secret
  my $submitter = eval {
    Metabase::User::Profile->from_struct($submission->{submitter});
  };
  die "invalid submitter profile: $@" unless $submitter; # bad profile provided

  my $submitted_secret = eval {
    Metabase::User::Secret->from_struct($submission->{secret});
  };
  die "invalid submitter secret: $@" unless $submitted_secret; # bad secret

  # check whether submitter profile is already in the Metabase
  my $profile_fact = eval {
    $self->librarian->extract($submitter->guid);
  };

  # if not found, maybe autocreate it
  if ( ! $profile_fact ) {
    die "unknown submitter profile" unless $self->autocreate_profile;
    eval {
      $self->librarian->store( $submitter ); 
      $self->secret_librarian->store( $submitted_secret ); 
    };
    die "error storing new submitter profile or secret: $@" if $@;
  }
  # else try to authenticate
  else {
    my $known_secret;
    my $matches = $self->secret_librarian->search(
      'core.type' => 'Metabase-User-Secret',
      'core.resource' => $submitter->resource,
    );
    $known_secret = $self->secret_librarian->extract( shift @$matches )
      if @$matches;

    die "submitter could not be authenticated"
      unless defined $known_secret
      and    $submitted_secret->content eq $known_secret->content;
  }

  # submitter is good!
  return ($submitter, $submitted_secret);
}

sub _validate_fact_struct {
  my ($self, $struct) = @_;

  die "no content provided" unless defined $struct->{content};

  for my $key ( qw/resource type schema_version guid creator_id/ ) {
    my $meta = $struct->{metadata}{core}{$key};
    die "no '$key' provided in core metadata"
      unless defined $meta;
    die "invalid '$key' provided in core metadata"
      unless ref $meta eq 'ARRAY';
    # XXX really should check meta validity: [ //str => 'abc' ], but lets wait
    # until we decide on sugar for metadata types -- dagolden, 2009-03-31
  }

  die "submissions must not include resource or content metadata"
    if $struct->{metadata}{content} or $struct->{metadata}{resource};
}

sub _check_permissions {
  my ($self, $profile, $action, $fact) = @_;

  # The devil may care, but we don't. -- rjbs, 2009-03-30
  return 1;
}

sub handle_submission {
  my ($self, $submission) = @_;

  # use Data::Dumper;
  # local $SIG{__WARN__} = sub { warn "@_: " . Dumper($struct); };

  my $fact_struct    = $submission->{fact};

  my ($profile, $secret) = eval { $self->__validate_submitter( $submission ) };
  die "reason: $@" unless $profile && $secret;

  $self->_validate_fact_struct($fact_struct);

  my $type = $fact_struct->{metadata}{core}{type}[1];

  die "'$type' is not an approved fact type"
    unless grep { $type eq $_ } $self->approved_types;

  my $class = Metabase::Fact->class_from_type($type);

  my $fact = eval { $class->from_struct($fact_struct) }
    or die "Unable to create a '$class' object: $@";

  $self->_check_permissions($profile => $secret => submit => $fact);

  return $self->enqueue($fact, $profile);
}

sub enqueue {
  my ($self, $fact, $profile) = @_;
  return $self->librarian->store($fact, $profile);
}

1;

__END__

=pod

=head1 NAME

Metabase::Gateway - Manage Metabase fact submission

=head1 SYNOPSIS

  my $mg = Metabase::Gateway->new( 
    fact_classes      => \@valid_fact_classes,
    librarian         => $librarian,
    secret_librarian  => $secret_librarian,
  );

  $mg->handle_submission({
    fact      => $fact_struct,
    submitter => $profile_struct
  });

=head1 DESCRIPTION

The Metabase::Gateway class manages submissions to the Metabase.  It
provides fact and submitter validation or authorization before storing
new facts in a Metabase.

=head1 USAGE

=head2 C<new>

  my $mg = Metabase::Gateway->new( 
    fact_classes      => \@valid_fact_classes,
    librarian         => $librarian,
    secret_librarian  => $secret_librarian,
  );

Gateway constructor.  Takes three required attributes C<fact_classes>,
C<librarian> and C<secret_librarian>.  See below for details.

=head1 ATTRIBUTES

=head2 C<approved_types>

Returns a list of approved fact types.  Automatically generated; cannot be
initialized.  Used for validating submitted facts.

=head2 C<autocreate_profile>

A boolean option.  If true, if a submission is from an unknown user profile,
the profile will be added to the Metabase.  If false, an exception will be thrown.
Default is false.

=head2 C<fact_classes>

Array reference containing a list of valid L<Metabase::Fact> subclasses. Only facts
from these classes may be added to the Metabase. Required.

=head2 C<librarian>

A librarian object to manage fact data. Required.

=head2 C<secret_librarian>

A librarian object to manage user profile data.  This is generally kept in a separate
data store to isolate user profile facts from public, searchable facts. Required.

=head1 METHODS

=head2 C<enqueue>

  $mg->enqueue( $fact, $profile );

Add a fact from a user (identified by a profile) to the Metabase the gateway is
managing.  Used internally by handle_submission.

=head2 C<handle_submission>

  $mg->handle_submission({
    fact      => $fact_struct,
    submitter => $profile_struct
  });

Extract a fact and profile from a deserialized data structure and add it to the
Metabase. The fact and profile structs are generated from the C<as_struct> method.

=head1 BUGS   

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

=over 

=item *

David A. Golden (DAGOLDEN)

=item *

Ricardo J. B. Signes (RJBS)

=back

=head1 COPYRIGHT AND LICENSE

 Portions copyright (c) 2008-2009 by David A. Golden
 Portions copyright (c) 2008-2009 by Ricardo J. B. Signes

Licensed under terms of Perl itself (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a 
copy of the License from http://dev.perl.org/licenses/

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

