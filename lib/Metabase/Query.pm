use 5.006;
use strict;
use warnings;

package Metabase::Query;
# ABSTRACT: Metabase query language

use Carp ();
use Moose::Role;

my @_ops = qw(
  op_eq
  op_ne
  op_gt
  op_lt
  op_ge
  op_le
  op_or
  op_and
  op_not
  op_like
  op_between
);

requires
  'prepare',  # convert query structure to native query form
  @_ops;      # implement each op in native form

has '_method_table' => (
  is    => ro,
  isa   => 'HashRef',
  default => sub {
    # '-eq' => 'op_eq', etc.
    map { (my $n = $_) =~ s/op_/-/; ($n => $_) } @_ops
  },
);

sub dispatch {
  my ($self, $op_name, $args) = @_;
  my $op_sub = $self->_method_table->{$op_name};
  if ( ! $op_method ) {
    Carp::confess "Query operator '$op_name' is unknown.\n";
  }
  return $self->$op_method($args);
}

1;

__END__

=for Pod::Coverage clone_metadata

=head1 SYNOPSIS

  package Metabase::Query::SQLite;

  use Moose;
  with 'Metabase::Query';

  # define Moose attributes

  sub prepare {
    my ( $self, $query ) = @_;

    # translate into SQLite WHERE clause
    ...

    return $where;
  }

  sub op_eq {
    my ( $self, $args ) = @_;
    my $field = _validate_field( $args->[0] ); # no SQL injection!
    return [ "$field = ?", $arg->[1] ];
  }

  # XXX SHOW -and with dispatch

  # ... implement all other required ops ...

=head1 DESCRIPTION

This role describes the simplified query language for use with Metabase
and defines the necessary methods to implement it for any particular
Metabase backend.

=head1 USAGE

The query is expressed as a data structure of the form:

  {
    -where => [ $operator => \@arguments ]
    -order => [ $direction => \@field_list ]
    -limit => $number,
  }

XXX revise further

  [ OPERATOR => EXPRESSION ]


  [ FIELD => OPERATOR => EXPRESSION ]

  [ -or => [CONSTRAINT1, CONSTRAINT2, ...] ] # OR

  [ -and => [CONSTRAINT1, CONSTRAINT2, ...] ] # AND

  [ -not => CONSTRAINT ]

=head2 Operators and expressions

  COMPARATOR => VALUE         # Any of == != > >= < <=

  -between => VALUE1, VALUE2  # >= VALUE 1 and <= VALUE2

  -like => PATTERN            # where '%' is like regex '.+'

=head2 Ordering

  -asc  => FIELD
  -asc  => [ FIELD1, FIELD2 ]
  -desc => FIELD
  -desc => [ FIELD1, FIELD2 ]

=head2 Limit results

  -limit => NUMBER

=cut
