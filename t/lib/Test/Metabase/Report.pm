package Test::Metabase::Report;
use 5.006;
use strict;
use warnings;
use base 'Metabase::Report';

__PACKAGE__->load_fact_classes;

sub report_spec {
  return {
    'Test::Metabase::StringFact' => "1+",  # zero or more
  }
}

1;
