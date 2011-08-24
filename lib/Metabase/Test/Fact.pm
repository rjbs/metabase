use 5.006;
use strict;
use warnings;

package Metabase::Test::Fact;
# ABSTRACT: Test class for Metabase testing
# VERSION

# Metabase::Fact is not a Moose class
use parent 'Metabase::Fact::String';

sub content_metadata {
  my $self = shift;
  return {
    'size' => length $self->content,
    'WIDTH' => length $self->content,
  };
}

sub content_metadata_types {
  return {
    'size' => "//num",
    'WIDTH' => "//str",
  };
}

sub validate_content {
  my $self = shift;
  $self->SUPER::validate_content;
  die __PACKAGE__ . " content length must be greater than zero\n"
  if length $self->content < 0;
}

1;


