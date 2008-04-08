use strict;
use warnings;
package CPAN::Metabase::Fact::PrereqAnalysis;
use base 'CPAN::Metabase::Fact';

use YAML::XS ();

sub as_string {
  my ($self) = @_;
  return YAML::XS::Dump($as_string);
}

sub from_string {
  my ($self) = @_;
  return YAML::XS::Dump($as_string);
}

sub validate_content {
  my ($self) = @_;

  # XXX: Make this betterer. -- rjbs, 2008-04-08
  die "must be a hashref" unless ref $self->content eq 'HASH';
}

1;
