use 5.006;
use strict;
use warnings;

package Metabase::Query;
# ABSTRACT: Metabase query language

use Moose::Role;

requires 'prepare'; # native

1;

__END__

=for Pod::Coverage clone_metadata

=head1 SYNOPSIS

  package Metabase::Query::SQLite;
  use Metabase::Query;
  use Moose;
  with 'Metabase::Query';

  # define Moose attributes

  sub prepare {
    my ( $self, $query ) = @_;

    # translate into SQLite WHERE clause
    return $where;
  }


=head1 DESCRIPTION

This describes the interface for indexing and searching facts.  Implementations
must provide the C<add> and C<search> methods.

=head1 USAGE

=head2 Constraints

  { FIELD => COMPARISON }

  { FIELD1 => COMPARISION1, FIELD2 => COMPARISON2 } # AND

=head2 Comparisons

  { OPERATOR => VALUE }   # operator applied against value
  VALUE                   # shorthand for equality operator

=head2 Operators

  = != > >= < <=
  between
  like (?)

  XXX What about negation?

=head2 Ordering

  -asc  => FIELD
  -asc  => [ FIELD1, FIELD2 ]
  -desc => FIELD
  -desc => [ FIELD1, FIELD2 ]

=head3 Limit results

  -limit => NUMBER

=cut
