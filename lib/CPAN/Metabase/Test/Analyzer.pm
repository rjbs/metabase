use strict;
use warnings;

package CPAN::Metabase::Test::Analyzer;

our $VERSION = '0.001';

sub analyze {
  return { ProvidedBy => __PACKAGE__ . " " . __PACKAGE__->VERSION };
}

1;
