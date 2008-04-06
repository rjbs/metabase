use strict;
use warnings;
package CPAN::Metabase::Report;

sub new {
  my ($class, $arg) = @_;

  bless $arg => $class;
}

sub type {
  my ($self) = @_;
  return $self->{type};
}

sub dist_author {
  my ($self) = @_;
  $self->{dist_author};
}

sub dist_name {
  my ($self) = @_;
  $self->{dist_name};
}

sub as_string {
  my ($self) = @_;
  $self->{content};
}

sub guid {
  my ($self) = @_;
  $self->{guid};
}

sub metadata {
  my ($self) = @_;
  $self->{metadata};
}

1;
