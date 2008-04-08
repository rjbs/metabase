package CPAN::Metabase::Analyzer;
use Moose;

use CPAN::Metabase::Report;

sub handles_type { 0 }

sub validate {
  return;
}

sub analyze {
  my ($self, $report) = @_;

  $self->validate($report);
  return { }
}

sub fact_class { die 'no fact class supplied'; }

sub produce_report {
  my ($self, $request) = @_;

  my $analysis = $self->analyze($request);

  # The idea here is that analyzers only get to produce non-lcfirst keys.  This
  # might be a load of crap that should get ditched. -- rjbs, 2008-04-06
  die "invalid keys in response from analyzer"
    if grep { /^[a-z]/ } keys %$analysis;

  my $class = $self->fact_class;
  eval "require $class; 1" or die;
  $self->fact_class->new({
    dist_name   => $request->{dist_name},
    dist_author => $request->{dist_author},
    content     => $self->fact_class->content_from_string(
      $request->{content_ref}
    ),
  });
}
  
1;
