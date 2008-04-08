package CPAN::Metabase::Analyzer::TestFact;
use Moose;
extends 'CPAN::Metabase::Analyzer';

our $VERSION = '0.001';

sub fact_class { 'CPAN::Metabase::Fact::TestFact' }

1;
