use 5.006;
use strict;
use warnings;

package Metabase::Gateway;
# ABSTRACT: Manage Metabase fact submission
# VERSION

use Moose::Role;

use Metabase::Fact 0.018;
use Metabase::Librarian;
use Metabase::User::Profile;
use Metabase::User::Secret;
use Module::Runtime qw( require_module );
use CHI;
use namespace::autoclean;

requires '_build_public_librarian';
requires '_build_private_librarian';
requires '_build_fact_classes';

has public_librarian => (
  is       => 'ro',
  isa      => 'Metabase::Librarian',
  lazy     => 1,
  builder  => '_build_public_librarian',
);

has private_librarian => (
  is       => 'ro',
  isa      => 'Metabase::Librarian',
  lazy     => 1,
  builder  => '_build_private_librarian',
);

# XXX life becomes a lot easier if we say that fact classes MUST have 1-to-1
# relationship with a .pm file. -- dagolden, 2009-03-31

has fact_classes => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  auto_deref => 1,
  lazy     => 1,
  builder => '_build_fact_classes',
);

has approved_types => (
  is          =>  'ro',
  isa         =>  'ArrayRef[Str]',
  auto_deref  => 1,
  lazy        => 1,
  builder     => '_build_approved_types',
  init_arg    => undef,
);

has disable_security => (
  is          => 'ro',
  isa         => 'Bool',
  default     => 0,
);

has allow_registration => (
  is          => 'ro',
  isa         => 'Bool',
  default     => 1,
);

has authentication_timeout => (
  is          => 'ro',
  isa         => 'Int',
  default     => 600,
);

has cache_options => (
  is          => 'ro',
  isa         => 'HashRef',
  default     => sub { my $hash = {}; return { driver => 'Memory', datastore => $hash } },
);

has _cache => (
  is          => 'ro',
  isa         => 'CHI::Driver',
  lazy        => 1,
  builder     => '_build_cache',
);

# create a CHI cache
sub _build_cache {
  my ($self) = @_;
  return CHI->new( %{ $self->cache_options } );
}

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
  return [ map { require_module($_); $_->type } @approved ];
}

# for use in handle_XXXX methods
sub _fatal {
  my ($self, $code, $reason, $details) = @_;
  $code ||= 500;
  $reason ||= "unknown error";
  $details ||= '';
  chomp $details;
  my $message = "$code\: $reason";
  $message .= ": $details" if $details;
  die "$message\n";
}

sub _validate_resource {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

sub _validate_submitter {
  my ($self, $user_guid, $user_secret) = @_;

  return 1 if $self->disable_security;

  # did we get arguments?
  die "no user identity provided\n"
    unless $user_guid;
  die "no user secret provided\n"
    unless $user_secret;

  my $user_resource = "metabase:user:$user_guid";

  my $secret = $self->_cache->get("secret/$user_guid");

  if ( ! defined $secret ) {
    # check if we have a secret on file
    eval {
      my $found = $self->private_librarian->search(
          'core.type' => 'Metabase-User-Secret',
          'core.resource' => $user_resource,
      );
      unless ( defined $found->[0] ) {
        die "credentials for $user_resource not found\n";
      }
      my $obj = $self->private_librarian->extract($found->[0]);
      # if we haven't died, we have it, so cache it
      $secret = $obj->content;
      $self->_cache->set(
        "secret/$user_guid", $secret, $self->authentication_timeout
      );
    };
  }

  # match against submitted secret
  die "authentication failed for $user_resource\n"
    unless defined $secret && $user_secret eq $secret;

  # submitter is good!
  return 1;
}

sub _validate_fact_struct {
  my ($self, $struct, @approved) = @_;

  # exists and has type
  die "no fact provide" unless defined $struct;
  die "fact type not provided" unless defined $struct->{metadata}{core}{type};

  # approved fact type
  my $type = $struct->{metadata}{core}{type};
  unless ( grep { $type eq $_ } @approved ) {
    die "$type is not an approved fact type\n";
  }

  # has content
  die "no content provided" unless defined $struct->{content};

  # required metadata
  for my $key ( qw/resource type schema_version guid creator creation_time/ ) {
    my $meta = $struct->{metadata}{core}{$key};
    die "no '$key' provided in core metadata"
      unless defined $meta;
    # XXX really should check meta validity: [ //str => 'abc' ], but lets wait
    # until we decide on sugar for metadata types -- dagolden, 2009-03-31
  }

  die "submissions must not include resource or content metadata"
    if $struct->{metadata}{content} or $struct->{metadata}{resource};

  return 1;
}

sub _check_permissions {
  my ($self, $user_guid, $action, $fact) = @_;

  # The devil may care, but we don't. -- rjbs, 2009-03-30

  # E.g. do we let a user submit a fact they aren't listed as the creator for?
  # -- dagolden, 2010-02-28

  return 1;
}

sub _thaw_fact {
  my ($self, $struct, @approved) = @_;

  $self->_validate_fact_struct($struct, @approved);
  my $type = $struct->{metadata}{core}{type};
  return Metabase::Fact->class_from_type($type)->from_struct($struct);
}

# NOTE ON ERRORS: die with _fatal( XXX => reason => details )
sub handle_submission {
  my ($self, $struct, $user_guid, $user_secret) = @_;

  # use Data::Dumper;
  # local $SIG{__WARN__} = sub { warn "@_: " . Dumper($struct); };

  # authenticate
  unless ( eval { $self->_validate_submitter( $user_guid, $user_secret ); 1 } ) {
    $self->_fatal( 401 => "unauthorized" => $@ );
  }

  # thaw
  my $fact = eval { $self->_thaw_fact($struct, $self->approved_types) };
  unless ( $fact ) {
    $self->_fatal( 400 => "invalid submission data" => $@ );
  }

  # action allowed for this submitter for this fact
  unless ( eval { $self->_check_permissions($user_guid => submit => $fact) } ) {
    $self->_fatal( 400 => "cannot accept fact from current submitter" => $@ );
  }

  # accepted by librarian
  my $guid = eval { $self->enqueue($fact) };
  unless ( $guid ) {
    $self->_fatal( 500 => "submission was not stored" => $@ );
  }

  return $guid;
}

# NOTE ON ERRORS: die with _fatal( XXX => reason => details )
sub handle_registration {
  my ($self, $profile_struct, $secret_struct) = @_;

  $self->_fatal( 400 => "new user registration disabled" )
    unless $self->allow_registration;

  # thaw profile
  my $profile = eval { $self->_thaw_fact($profile_struct, 'Metabase-User-Profile') };
  unless ( $profile ) {
    $self->_fatal( 400 => "invalid registration profile" => $@ );
  }

  # thaw secret
  my $secret = eval { $self->_thaw_fact($secret_struct, 'Metabase-User-Secret') };
  unless ( $secret ) {
    $self->_fatal( 400 => "invalid registration credential" => $@ );
  }

  # neither should exist
  if ( $self->public_librarian->exists( $profile->guid )
    || $self->private_librarian->exists( $secret->guid )
  ) {
    $self->_fatal( 400 => "already registered" );
  }

  # store with respective librarians
  my ($secret_guid, $profile_guid);
  eval {
    $secret_guid = $self->private_librarian->store( $secret );
    $profile_guid = $self->public_librarian->store( $profile );
  };
  unless ( $secret_guid && $profile_guid ) {
    $self->_fatal( 500 => "registration failed" => $@ );
  }

  # profile accepted by librarian
  return $profile_guid;
}

sub enqueue {
  my ($self, $fact) = @_;
  return $self->public_librarian->store($fact);
}


1;

__END__

=head1 SYNOPSIS

=head2 Creating a Gateway class

  use strict;
  use warnings;
  package Custom::Metabase;

  use Moose;
  with 'Metabase::Gateway';

  sub _build_fact_classes { ... }
  sub _build_public_librarian { ... }
  sub _build_private_librarian { ... }

=head2 Using a Gateway class

  my $mg = Custom::Gateway->new( @args );
  $mg->handle_submission( $fact_struct, $user_guid, $user_secret);

=head1 DESCRIPTION

The Metabase::Gateway role manages submissions to the Metabase.  It
provides fact and submitter validation or authorization before storing
new facts in a Metabase.

=head1 USAGE

=head2 Required methods

The following builders must be provided by the class that applies this role.
All three are lazy.

=head3  C<_build_fact_classes>

This builder must return an array reference of Metabase::Fact subclasses.

=head3  C<_build_public_librarian>

=head3  C<_build_private_librarian>

These builders must return Metabase::Librarian objects.

=head2 Configurable attributes

=head3 C<disable_security>

A boolean option.  If true, submitter profiles will not be authenticated.
(This is generally useful for testing, only.) Default is false.

=head3 C<allow_registration>

A boolean option.  If true, new submitter profiles and secrets may be
stored. Default is true.

=head3 C<authentication_timeout>

Number of seconds to cache user authentication data.  Defaults to 600.

=head3 C<cache_options>

A hash reference of constructor arguments for a L<CHI> cache. Defaults to
C<< { driver => 'Memory' } >>.

=head2 Generated attributes

=head3 C<approved_types>

Returns a list of approved fact types.  Used for validating submitted facts.

A "type" is a class name with "::" converted to "-", so this attribute
returns an arrayref of the C<fact_classes> attribute converted to types.

=head3 C<fact_classes>

Array reference containing a list of valid L<Metabase::Fact> subclasses. Only
facts from these classes may be added to the Metabase.

=head3 C<public_librarian>

A librarian object to manage fact data.

=head3 C<private_librarian>

A librarian object to manage user authentication data and possibly other
facts that should be segregated from searchable and retrievable facts.
This should not be the same as the public_librarian.

=head2 Methods provided

=head3 C<enqueue>

  $mg->enqueue( $fact );

Add a fact from a user (identified by a profile) via the public_librarian.
Used internally by handle_submission.

=head3 C<handle_submission>

  $mg->handle_submission( $fact_struct, $user_guid, $user_secret);

Extract a fact a deserialized data structure and add it to the Metabase via the
public_librarian. The fact is regenerated from the C<as_struct> method.

=head3 C<handle_registration>

  $mg->handle_registration( $profile_struct, $secret_struct );

Extract a new user profile and secret from deserialized data structures
and add them via the public_librarian and private_librarian, respectively.

=cut

