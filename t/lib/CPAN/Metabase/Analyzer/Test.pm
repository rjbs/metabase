package CPAN::Metabase::Analyzer::Test;
use Moose;
extends 'CPAN::Metabase::Analyzer';

our $VERSION = '0.001';

sub handles_type {
  return 1 if $_[1] eq 'CPAN::Metabase::Test';
  return;
}

sub analyze {
  return { ProvidedBy => __PACKAGE__ . " " . __PACKAGE__->VERSION };
}

1;
