use 5.006;
use strict;
use warnings;

package Metabase::Query;
# ABSTRACT: Generic Metabase query language role

use Carp ();
use List::AllUtils qw/all/;
use Moose::Role;

#--------------------------------------------------------------------------#
# Operators and validator definitions
#--------------------------------------------------------------------------#

my %ops = (
  op_not      => 'UP', # unary predicate
  op_or       => 'PL', # predicate list
  op_and      => 'PL',
  op_eq       => 'FV', # field, value
  op_ne       => 'FV',
  op_gt       => 'FV',
  op_lt       => 'FV',
  op_ge       => 'FV',
  op_le       => 'FV',
  op_like     => 'FV',
  op_between  => 'FLH', # field, value, value
);

my %validators = (
  PL  => sub { all {_is_predicate($_)} @_ },
  UP  => sub { @_ == 1 and _is_predicate($_[0]) },
  FV  => sub { @_ == 2 and _field_ok($_[0]) and _value_ok($_[1]) },
  FHL => sub { @_ == 3 and _field_ok($_[0]) and all {_value_ok($_)} @_[1,2] },
);

#--------------------------------------------------------------------------#
# role parameters and attributes
#--------------------------------------------------------------------------#

requires
  'translate_query',  # convert to native form
  keys(%ops);         # implement each op in native form

has '_method_table' => (
  is    => 'ro',
  isa   => 'HashRef',
  default => sub {
    # '-eq' => 'op_eq', etc.
    return { map { (my $n = $_) =~ s/op_/-/; ($n => $_) } keys %ops }
  },
);

has '_validators' => (
  is => 'ro',
  isa   => 'HashRef',
  default => sub {
    # 'op_eq' => \&coderef
    return { map { $_ => $validators{$ops{$_}} } keys %ops }
  },
);

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

=method dispatch_query_op

  $result = $self->dispatch_query_op([-eq => $field, $value]);

Validates that a predicate has a valid operator name, validates
the arguments are correctly specified, and dispatches to the
appropriate method for the operator name (e.g. C<op_eq>).

=cut

sub dispatch_query_op {
  my ($self, $predicate) = @_;
  if ( ! _is_predicate( $predicate ) ) {
    Carp::confess "dispatch_query_op() argument is not a valid predicate";
  }

  my ($op_name, @args) = @$predicate;
  my $op_method = $self->_method_table->{$op_name};

  if ( ! $op_method ) {
    Carp::confess "Query operator '$op_name' is unknown.\n";
  }
  if ( ! @args ) {
    Carp::confess "No query arguments provided for $op_name\n";
  }
  if ( ! $self->_validators->{$op_method}->(@args) ) {
    Carp::confess "Query arguments invalid for $op_name\: @args\n";
  }

  return $self->$op_method(@args);
}

=method get_native_query

  $result = $self->get_native_query( $query );
  @result = $self->get_native_query( $query );

Translates the Metabase query data structure into a backend-native
scalar (string, data-structure, etc).  It validates the structure
of the query and then calls the C<translate_query> method, which
must be provided by the class that implements this role.

The C<translate_query> method will be called with the same
context (scalar or list) as the call to C<get_native_query>.

=cut

sub get_native_query {
  my ($self, $query) = @_;
  # XXX validate keys
  # XXX validate structure
  # XXX die if invalid
  return $self->translate_query( $query );
}

#--------------------------------------------------------------------------#
# private helper functions
#--------------------------------------------------------------------------#

sub _is_predicate { ref($_[0]) eq 'ARRAY' }

sub _field_ok { $_[0] =~ m{\A[a-z_.]+\z}i }

sub _value_ok { ! ref $_[0] }

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

    # extract '-where' translate to SQL
    my $pred = $query->{-where};
    my $where = !$pred ? "" : "WHERE " . $self->dispatch_query_op($pred);

    # extract '-limit' and '-order' and translate to SQL
    ...

    return "$where $order $limit";
  }

  sub op_eq {
    my ( $self, @args ) = @_;
    return [ "$field = ?", $arg[1] ];
  }

  sub op_and {
    my ( $self, @args ) = @_;

    my @predicates =  map { "($_)" }
                      map { $self->dispatch_query_op($_) } @args;

    return join(" AND ", @predicates);
  }

  # ... implement all other required ops ...

=head1 DESCRIPTION

This role describes the simplified query language for use with Metabase
and defines the necessary methods to implement it for any particular
Metabase backend.

A query is expressed as a data structure of the form:

  {
    -where => [ $operator => @arguments ]
    -order => [ $direction => $field, ... ]
    -limit => $number,
  }

Arguments to an operator must be scalar values, or in the case of
logic operators, must be array references of operator/argument pairs.

=head2 Where clauses

A where clause predicate must be given as an arrayref consisting of an
operator name and a list of one or more arguments.

  -where => [ $operator => @arguments ]

Some operators take a field name as the first argument. A field name
must match the expression C<qr/\A[a-z._]+\z/i>

=head3 Logic operators

Logic operators take predicates as arguments.  The C<-and> and C<-or>
operators take a list of predicates.  The C<-not> operator takes only
a single predicate as an argument.

  [ -and => @predicates ]
  [ -or  => @predicates ]
  [ -not => $one_predicate ]

=head3 Comparision operators

Most comparison operators are binary and take two arguments.  The first
must be the field name to which the operation applies.  The second
argument must be a non-reference scalar value that the operation is
comparing against.

  [ -eq => $field => $value ] # equal
  [ -ne => $field => $value ] # not equal
  [ -gt => $field => $value ] # greater than
  [ -ge => $field => $value ] # greater than or equal to
  [ -lt => $field => $value ] # less than
  [ -le => $field => $value ] # less than or equal to

The exception is the C<-between> operator, which takes a field, a low value
and a high value:

  [ -between => $field => $low, $high ]

=head3 Matching operator

The matching operator provides rudimentary pattern matching.

  [ -like => $field => $match_string ]

The match string specifies a pattern to match.  A percent sign (C<%>)
matches zero or more characters and a period (C<.>) matches a single
character.

=head2 Order clauses

A desired order of results may be specified with an array reference
containing direction and field name pairs.  Field names must follow the
same rules as for L</Where clauses>.  Valid directions are C<-asc> and
C<-desc>.

  -order => [ -asc => $field1 ]
  -order => [ -asc => $field1, -desc => $field2 ]

Not all backend will support mixed ascending and descending field
ordering and backends may throw an error if ordering is not possible.

=head2 Limit clauses

A limit on the number of results returned is specified by a simple
key-value pair:

  -limit => NUMBER

The number must be a non-negative integer.  A given backend should make
a best efforts basis to respect the limit request, but the success of
a limit request may be constrained by the nature of a particular backend
index.

=head1 EXAMPLES

Here is an example example query to return the 10 most recent CPAN Testers
reports by a single submitter (specified by creator URI), excluding
'NA' reports:

  {
    -where => [
      -and =>
        [ -eq => 'core.creator' => $creator_uri ],
        [ -eq => 'core.type' => 'CPAN-Testers-Report'],
    ],
    -order => [ -desc => 'core.update_time' ],
    -limit => 10,
  }

=head2 METHODS REQUIRED

=head3 translate_query

  my $native = $self->translate_query( $query );

This method should take a query data structure in the form described in this
document and return a backend-native query scalar (WHERE/ORDER/LIMIT clauses or
comparable data structure).  In practice, this means calling C<dispatch> on
individual predicates and assembling the results appropriately.

=head3 Operator methods

Classes implementing this role must provide the following methods to
implement the query operations in the appropriate backend-specific
syntax.

=for :list
* op_not
* op_or
* op_and
* op_eq
* op_ne
* op_gt
* op_lt
* op_ge
* op_le
* op_like
* op_between

=cut

