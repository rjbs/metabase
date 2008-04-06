use strict;
use warnings;

package CPAN::Metabase::Gateway;

my %USER_FOR_KEY = (
  xyzzy => 'rjbs',
  plugh => 'D. A. Golden',
);

my %HANDLER_FOR = (
  'CPAN::Metabase::Test' => 'CPAN::Metabase::Test::Analyzer',
);

sub handle {
  my ($self, $request) = @_;

  # XXX Yeah, uh, in the future this won't be a hashref. -- rjbs, 2008-04-06
  $request ||= {};

  die "unknown user" unless my $user = $USER_FOR_KEY{ $request->{'auth.key'} };

  die "unknown datatype" unless my $handler = $HANDLER_FOR{ $request->{type} };

  $request->{guid} = Data::GUID->new->as_string;

  eval "require $handler; 1" or die;

  my $metadata = $handler->analyze($request);

  die "invalid keys in response from analyzer"
    if grep { /^[a-z]/ } keys %$metadata;

  my $report = CPAN::Metabase::Report->new({
    (map { $_ => $request->{$_} } qw(dist_name dist_author type guid)),
    content  => $request->{content},
    metadata => {
      %$metadata,
      user => $user,
      type => $request->{type},
      handler => $handler,
    },
  });
  
  CPAN::Metabase::Injector->inject_report($report);

  return 1;
}

1;
