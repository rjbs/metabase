use 5.006;
use strict;
use warnings;

package Metabase::Index::SimpleDB;
# ABSTRACT: Metabase Amazon SimpleDB index

use Moose;
use SimpleDB::Client;
use Try::Tiny;

with 'Metabase::Index';

has 'access_key_id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'secret_access_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'domain' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'simpledb' => (
    is      => 'ro',
    isa     => 'SimpleDB::Client',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $sdb = SimpleDB::Client->new(
            access_key => $self->access_key_id,
            secret_key => $self->secret_access_key
        );
        $sdb->send_request('CreateDomain', { DomainName => $self->domain });
        return $sdb;
    },
);

# XXX not currently used, but available for future
sub _format_int {
    my ($self, $value) = @_;
    $value ||= 0; # init
    return sprintf("%015d",$value+1000000000);
}

sub _get_search_sql {
  my ( $self, $select, $spec ) = @_;

  my ($where, $limit) = $self->get_native_query($spec);

  my $domain = $self->domain;
  my $sql = qq{$select from `$domain` $where};

  return ($sql, $limit);
}

sub add {
    my ( $self, $fact ) = @_;

    Carp::confess("can't index a Fact without a GUID") unless $fact->guid;

    my $metadata = $self->clone_metadata( $fact );

    my $i = 0;
    my @attributes;
    foreach my $key ( keys %$metadata ) {
        my $value = $metadata->{$key};
        push @attributes,
            "Attribute.$i.Name"    => $key,
            "Attribute.$i.Value"   => $value,
            # XXX not using replace is an optimization -- dagolden, 2010-04-29
#            "Attribute.$i.Replace" => 'true'; # XXX optimization -- dagolden, 2010-04-29
        $i++;
    }

    my $response = $self->simpledb->send_request(
        'PutAttributes',
        {   DomainName => $self->domain,
            ItemName   => lc $fact->guid,
            @attributes,
        }
    );
}

my $_count_extractor = sub {
  my $response = shift;
  my $items = $response->{SelectResult}{Item};

  # the following may not be necessary as of SimpleDB::Class 1.0000
  $items = [ $items ] unless ref $items eq 'ARRAY';

  my $count = 0;
  for my $i (@$items) {
    next unless $i->{Name} eq 'Domain';
    $count += $i->{Attribute}{Value};
  }

  return $count, $count;
};

sub count {
  my ( $self, %spec) = @_;
  my ($sql, $limit) = $self->_get_search_sql("select count(*)", \%spec );
  return Data::Stream::Bulk::Callback->new(
    callback => $self->_get_fetch_callback($sql, $limit, $_count_extractor)
  );
}

my $_item_extractor = sub {
  my $response = shift;
  my $items = $response->{SelectResult}{Item};

  # the following may not be necessary as of SimpleDB::Class 1.0000
  $items = [ $items ] unless ref $items eq 'ARRAY';

  my $result = [ map { $_->{Name} } @$items ];
  return $result, scalar @$result;
};

sub query {
  my ( $self, %spec) = @_;
  my ($sql, $limit) = $self->_get_search_sql("select ItemName()", \%spec );
  return Data::Stream::Bulk::Callback->new(
    callback => $self->_get_fetch_callback($sql, $limit, $_item_extractor)
  );
}

sub _generate_fetch_callback {
  my ($self, $sql, $limit, $extractor) = @_;
    # prepare request
  my $request = { SelectExpression => $sql };
  my $total_count = 0;
  my $finished = 0;

  return sub {
    return [] if $finished;
    FETCH: {
      my ($response, $result, $query_count);
      try {
        $response = $self->simpledb->send_request( 'Select', $request )
      } catch {
        Carp::confess("Got error '$_' from '$sql'");
      };

      if ( exists $response->{SelectResult}{Item} ) {
        ($result, $query_count) = $extractor->($response);
        $total_count += $query_count;
      }

      # If SimpleDB promises more data, then update the request
      if ( exists $response->{SelectResult}{NextToken} ) {
        $request->{NextToken} = $response->{SelectResult}{NextToken};
        # if promised more, but have nothing now, repeat query right away
        redo FETCH unless @$result;
        # if we have more than we need, flag that we're done
        $finished++ if $limit && $total_count >= $limit;
      }
      # No promise of more, so we're done
      else {
        $finished++;
      }

      # return whatever we got
      return $result;
    }
  };
}

# DO NOT lc() GUID
sub delete {
    my ( $self, $guid ) = @_;

    Carp::confess("can't delete without a GUID") unless $guid;

    my $response = $self->simpledb->send_request(
        'DeleteAttributes',
        {   DomainName => $self->domain,
            ItemName   => $guid,
        }
    );
}

#--------------------------------------------------------------------------#
# required by Metabase::Query
#
# ops return closures that define the necessary logic when called
# with hash of index fields
#--------------------------------------------------------------------------#

sub _quote_field {
  my ($self, $field) = @_;
  return qq{`$field`};
}

sub _quote_value {
  my ($self, $value) = @_;
  $value =~ s{"}{""}g;
  return qq{"$value"};
}

sub translate_query {
  my ( $self, $spec ) = @_;

  my (@parts, $limit);

  # where
  if ( defined $spec->{-where} ) {
    push @parts, "where " . $self->dispatch_query_op( $spec->{-where} );
  }

  # order
  if ( defined $spec->{-order} ) {
    my @order_pairs = @{$spec->{-order}};

    Carp::confess("Only one of '-asc' or '-desc' allowed")
      if @{$spec->{-order}} > 2;

    my ($dir, $field) = @{$spec->{-order}};

    Carp::confess("'$field' must be used in WHERE predicates")
      unless $parts[0] && $parts[0] =~ /\Q$field\E/;

    $field = $self->_quote_field( $field );
    $dir =~ s/^-//;
    push @parts, qq{order by $field $dir};
  }

  # limit
  if ( $limit = $spec->{-limit} or $spec->{-order} ) {
    Carp::confess("-limit requires -asc or -desc")
      unless $spec->{-order};
    $limit ||= 2500; # if ordered and no limit, use high default
    push @parts, qq{limit $limit};
  }

  return join( q{ }, @parts ), $limit;
}

sub op_eq {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " = " . $self->_quote_val($val);
}

sub op_ne {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " != " . $self->_quote_val($val);
}

sub op_gt {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " > " . $self->_quote_val($val);
}

sub op_lt {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " < " . $self->_quote_val($val);
}

sub op_ge {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " >= " . $self->_quote_val($val);
}

sub op_le {
  my ($self, $field, $val) = @_;
  return $self->_quote_field($field) . " <=" . $self->_quote_val($val);
}

sub op_between {
  my ($self, $field, $low, $high) = @_;
  return $self->_quote_field($field) . " between "
    . $self->_quote_val($low) . " and " . $self->_quote_val($high);
}

sub op_like {
  my ($self, $field, $val) = @_;
  # XXX really should quote/check $val
  return $self->_quote_field($field) . " like " . $self->_quote_val($val);
}

sub op_not {
  my ($self, $pred) = @_;
  my $clause = $self->dispatch_query_op($pred);
  return "NOT ($clause)";
}

sub op_or {
  my ($self, @args) = @_;
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  return join(" or ", map { "($_)" } @predicates);
}

sub op_and {
  my ($self, @args) = @_;
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  return join(" and ", map { "($_)" } @predicates);
}

1;

__END__

=attr access_key_id (required)

An Amazon Access Key ID.

=attr secret_access_key (required)

The Secret Access Key that goes with the Amazon Access Key ID

=attr domain (required)

The SimpleDB domain to store index data in.  This should be unique for
each Metabase installation.

=for Pod::Coverage::TrustPod add search exists delete count

=head1 SYNOPSIS

  require Metabase::Index::SimpleDB;
  Metabase::Index:SimpleDB->new(
    access_key_id => 'XXX',
    secret_access_key => 'XXX',
    domain     => 'metabase',
  );

=head1 DESCRIPTION

This is an implementation of the L<Metabase::Index> and L<Metabase::Query>
roles using Amazon SimpleDB.

=head1 USAGE

See below for constructor attributes.  See L<Metabase::Index>,
L<Metabase::Query> and L<Metabase::Librarian> for details on usage.

=head1 LIMITATIONS

Search queries have limitations based on the underlying SimpleDB search
API.  Specifically:

=over

=item lexicographic comparison

All comparisons are done lexicographically, even when the field or comparision
value appears to be a number.

=item -order

SimpleDB only supports sorting on a single attribute.  Any field used
for sorting must also have been included as part of a query constraint
in the C<-where> expression.

=item -limit

Limit is only supported when a query is sorted.

=back

=cut
