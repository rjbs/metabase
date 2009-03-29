package CPAN::Metabase::Gateway;
use Moose;

use CPAN::Metabase::Librarian;
use Data::GUID;

has fact_classes => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  auto_deref => 1,
  required   => 1,
);

has librarian => (
  is       => 'ro',
  isa      => 'CPAN::Metabase::Librarian',
  required => 1,
);

sub _validate_resource {
  my ($self, $request) = @_;

  # XXX Well... yeah, eventually we'll want to reject reports for dists that
  # don't, you know, exist. -- rjbs, 2008-04-06
  1;
}

my %IS_USER = map {; $_ => 1 } qw(rjbs dagolden);
sub _validate_user {
  my $req = $_[1]; 
  return $IS_USER{ $req->{metadata}{core}{user_id}[1] };
}

sub handle {
  my ($self, $struct) = @_;

  $struct = { %{ $struct || {} } };

  use Data::Dumper;
  local $SIG{__WARN__} = sub { warn "@_: " . Dumper($struct); };

  die "unknown user" unless $self->_validate_user($struct);
  die "unknown dist" unless $self->_validate_resource($struct);
  die "submissions must not include resource or content metadata"
    if $struct->{metadata}{content} or $struct->{metadata}{resource};

  my $type = $struct->{metadata}{core}{type}[1];

  my $fact;
  FACT_CLASS: for my $fact_class ($self->fact_classes) {
    eval "require $fact_class; 1" or die;
    next FACT_CLASS unless $fact_class->type eq $type;
    $fact = eval { $fact_class->from_struct($struct) };
    die $@ unless $fact;
  }

  my $guid = $self->librarian->store($fact);
}

1;
