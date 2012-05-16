use 5.006;
use strict;
use warnings;

package Metabase::Index;
# ABSTRACT: Interface for Metabase indexing
# VERSION

use Moose::Role;

with 'Metabase::Query';

requires 'add';
requires 'query';
requires 'count';
requires 'delete';
requires 'initialize';

sub exists {
    my ($self, $guid) = @_;
    # if desired guid in upper case, fix it
    return scalar @{ $self->search(-where => [-eq =>'core.guid'=>lc $guid])};
}

sub clone_metadata {
  my ($self, $fact) = @_;
  my %metadata;

  for my $type (qw(core content resource)) {
    my $method = "$type\_metadata";
    my $data   = $fact->$method || {};

    KEY: for my $key (keys %$data) {
      next KEY unless defined $data->{$key};
      # I'm just starting with a strict-ish set.  We can tighten or loosen
      # parts of this later. -- rjbs, 2009-03-28
      die "invalid metadata key '$key'" unless $key =~ /\A[-_a-z0-9.]+\z/i;
      $metadata{ "$type.$key" } = $data->{$key};
    }
  }

  for my $key ( qw/resource creator/ ) {
    $metadata{"core.$key"} = $metadata{"core.$key"}->resource
      if exists $metadata{"core.$key"};
  }

  return \%metadata;
}

sub search {
  my ($self, %spec) = @_;
  my $result = $self->query(%spec);
  return $result->is_done ? [] : [ $result->all ];
}

1;

__END__

=for Pod::Coverage some_method

=head1 SYNOPSIS

  package Metabase::Index::Bar;
  use Metabase::Fact;
  use Moose;
  with 'Metabase::Index';

  # define Moose attributes

  sub add {
    my ( $self, $fact ) = @_;
    # index a fact
  }

  sub search {
    my ( $self, %spec ) = @_;
    # conduct search
    return \@matches;
  }

  # ... implement other required methods ... *


=head1 DESCRIPTION

This module defines a L<Moose::Role> for indexing and searching facts.
Implementations for any particular backend indexer must provide all of the
required methods described below.

=head1 METHODS

The following methods are provided by the C<Metabase::Index> role.

=head2 C<clone_metadata>

  my $metadata = $index->clone_metadata( $fact )

Assembles all three metadata types ('core', 'resource' and 'content')
into a single-level hash by joining the type and the metadata name with
a period.  E.g. the C<guid>. field from the core metadata becomes C<core.guid>.

=head2 C<exists>

  if ( $index->exists( $guid ) ) { do_stuff() }

This method that calls C<search()> on the given GUID and returns a boolean
value.

=head2 C<search> DEPRECATED

  for $guid ( @{ $index->search( %query ) } ) {
    # do stuff
  }

Returns an arrayref of GUIDs satisfying the query parameters.  The query must
be given in the form described in L<Metabase::Query>.

This method is deprecated in favor of C<query> and is included for
backwards compatibility.  It calls C<query> and accumulates all results
before returning.

=head1 METHODS REQUIRED

The following methods must be implemented by consumers of the
C<Metabase::Index> role.

Errors should throw exceptions rather than return false values.

=head2 C<add>

  $index->add( $fact );

Adds the given fact to the Metabase Index;

=head2 C<query>

  my $result = $index->search( %query );
  while ( ! $result->is_done ) {
    for $guid ( $result->items ) {
      # do stuff
    }
  }

Returns a L<Data::Stream::Bulk> iterator.  Calling the iterator will
return lists of GUIDs satisfying the query parameters.  The query must
be given in the form described in L<Metabase::Query>.  Valid fields for search
are the keys from core, content, or resource metadata.  E.g.

  core.guid
  core.type
  core.resource
  resource.somefield
  content.somefield

See L<Data::Stream::Bulk> for more on the iterator API.

=head2 C<count>

  my $count = $index->count( %query );

Takes query parameters and returns a count of facts satisfying the
parameters.  The query must be given in the form described in
L<Metabase::Query>, though C<-order> and C<-limit> clauses should not
be included.

There is no guarantee that this query will take any less time than calling
C<query> and counting all the results, though back end implementations are
encouraged to optimize if possible.  In the worst case, all results could be
retrieved and then discarded.

=head2 C<delete>

  $index->delete( $guid );

Removes the fact with matching GUID from the index.

=head2 C<initialize>

  sub initialize {
    my ($self, @fact_classes) = @_;
    # prepare backend to store data (e.g. create database, etc.)
    return;
  }

Allows a backend to prepare to store various classes.

=head2 Metabase::Query methods

As C<Metabase::Index> consumes the C<Metabase::Query> role, all
the required methods from that role must be implemented as well.

=cut
