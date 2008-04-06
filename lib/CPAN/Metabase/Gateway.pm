package CPAN::Metabase::Gateway;
use Moose;

my %USER_FOR_KEY = (
  xyzzy => 'rjbs',
  plugh => 'D. A. Golden',
);

has analyzers => (
  is  => 'ro',
  isa => 'ArrayRef[CPAN::Metabase::Analyzer]',
  auto_deref => 1,
);

# This is no good.  The analyzers won't be set because the TC on analyzers
# can't pass if they weren't loaded. -- rjbs, 2008-04-06
# sub BUILD {
#   my ($self) = @_;
#   eval "require $_; 1" or die for $self->analyzers;
# }

sub handle {
  my ($self, $request) = @_;

  # XXX Yeah, uh, in the future this won't be a hashref. -- rjbs, 2008-04-06
  $request ||= {};

  die "unknown user" unless my $user = $USER_FOR_KEY{ $request->{'auth.key'} };

  my $analyzer;
  CANDIDATE: for my $candidate ($self->analyzers) {
    if ($candidate->handles_type($request->{type})) {
      $analyzer = $candidate;
      last CANDIDATE;
    }
  }

  die "unknown datatype" unless $analyzer;

  $request->{guid} = Data::GUID->new->as_string;

  my $metadata = $analyzer->analyze($request);

  die "invalid keys in response from analyzer"
    if grep { /^[a-z]/ } keys %$metadata;

  my $report = CPAN::Metabase::Report->new({
    (map { $_ => $request->{$_} } qw(dist_name dist_author type guid)),
    content  => $request->{content},
    metadata => {
      %$metadata,
      user => $user,
      type => $request->{type},
      handler => $analyzer,
    },
  });
  
  CPAN::Metabase::Injector->inject_report($report);

  return 1;
}

1;
