package Test::Metabase::StringFact;
use 5.006;
use strict;
use warnings;
use base 'Metabase::Fact::String';

sub content_metadata {
  my $self = shift;
  return {
    'size' => [ Num => length $self->content ],
  };
}

sub validate_content {
  my $self = shift;
  $self->SUPER::validate_content;
  die __PACKAGE__ . " content length must be greater than zero\n"
  if length $self->content < 0;
}

1;
