use strict;
use warnings;
package CPAN::Metabase::Fact::PrereqAnalysis;
use base 'CPAN::Metabase::Fact';

use YAML::XS ();

# XXX: remove this after merging with dagolden -- rjbs, 2008-04-08
sub type { 'CPAN-Metabase-Fact-PrereqAnalysis' }

sub content_as_string {
  my ($self) = @_;
  return YAML::XS::Dump($self->content);
}

sub content_from_string {
  my ($self, $string) = @_;

  YAML::XS::Load($string);
}

sub validate_content {
  my ($self) = @_;

  # XXX: Make this betterer. -- rjbs, 2008-04-08
  die "must be a hashref" unless ref $self->content eq 'HASH';
}

1;
