use 5.006;
use strict;
use warnings;

package Metabase::Index::FlatFile;
# ABSTRACT: Metabase flat-file index
# VERSION

use Moose;
use Moose::Util::TypeConstraints;

use Carp ();
use Data::Stream::Bulk::Array;
use Fcntl ':flock';
use IO::File ();
use List::AllUtils qw/any all/;
use JSON 2 qw/encode_json decode_json/;
use Regexp::SQL::LIKE 0.001 qw/to_regexp/;
use Tie::File;
use MooseX::Types::Path::Class;

with 'Metabase::Index';

has 'index_file' => (
    is => 'ro',
    isa => 'Path::Class::File',
    coerce => 1,
    required => 1,
);

sub initialize {}

sub add {
    my ($self, $fact) = @_;
    Carp::confess( "can't index a Fact without a GUID" ) unless $fact->guid;

    my $metadata = $self->clone_metadata( $fact );
    my $line = encode_json($metadata);
    my $filename = $self->index_file;
    my $fh = IO::File->new( $filename, "a+" )
        or Carp::confess( "Couldn't append to '$filename': $!" );
    $fh->binmode(':raw');
    flock $fh, LOCK_EX;
    {
        seek $fh, 2, 0; # end
        print {$fh} $line, "\n";
    }
    $fh->close;
}

sub query {
    my ($self, %spec) = @_;

    my $filename = $self->index_file;
    return Data::Stream::Bulk::Array->new( array => [] )
      unless -f $filename;

    my $query = $self->get_native_query( \%spec );
    my $fh = IO::File->new( $filename, "r" )
        or Carp::confess( "Couldn't read from '$filename': $!" );
    $fh->binmode(':raw');
    my @matches;
    flock $fh, LOCK_SH;
    {
        while ( my $line = <$fh> ) {
            my $parsed = decode_json($line);
            push @matches, $parsed if $query->{-where}->($parsed);
        }
    }
    $fh->close;

    # sort
    if ( exists $spec{-order} ) {
      @matches = sort { $spec{-order}->($a, $b) } @matches;
    }

    # limit
    if ( exists $spec{-limit} ) {
      @matches = splice(@matches, 0, $spec{-limit});
    }

    return Data::Stream::Bulk::Array->new(
      array => [ map { $_->{'core.guid'} } @matches ]
    );
}

sub count {
  my ($self, %spec) = @_;
  my $result = [ $self->query(%spec)->all ];
  return scalar @$result;
}

sub delete {
  my ($self, $guid) = @_;

  my @index;
  my $obj = tie @index, 'Tie::File', $self->index_file->stringify;
  $obj->flock(LOCK_EX);
  {
    for my $i ( 0 .. $#index ) {
      my $parsed = decode_json($index[$i]);
      if ($parsed->{'core.guid'} eq $guid ) {
        splice @index, $i, 1; # delete that row
        last;
      }
    }
  }
  undef $obj;
  untie @index;

  return 1;
}

#--------------------------------------------------------------------------#
# required by Metabase::Query
#
# ops return closures that define the necessary logic when called
# with hash of index fields
#--------------------------------------------------------------------------#

sub translate_query {
  my ( $self, $spec ) = @_;

  # translate search query into a coderef
  if ( exists $spec->{-where} ) {
    $spec->{-where} = $self->dispatch_query_op( $spec->{-where} );
  }
  else {
    $spec->{-where} = sub { 1 };
  }

  if ( exists $spec->{-order} ) {
    my $sort_fcn = sub { 0 };
    my @order = @{$spec->{-order}};
    while ( @order ) {
      my ($dir, $field) = splice( @order, 0, 2);
      my $old_fcn = $sort_fcn;
      my $new_fcn = ($dir eq '-asc')
        ? sub { my ($i, $j) = @_; return $i->{$field} cmp $j->{$field} }
        : sub { my ($i, $j) = @_; return $j->{$field} cmp $i->{$field} }
        ;
      $sort_fcn = sub {
        my ($i, $j) = @_;
        return $old_fcn->($i, $j) || $new_fcn->($i, $j);
      }
    }
    $spec->{-order} = $sort_fcn;
  }

  return $spec;
}

sub op_eq {
  my ($self, $field, $val) = @_;
  return sub {
    my $data = shift->{$field} || '';
    return $data eq $val
  };
}

sub op_ne {
  my ($self, $field, $val) = @_;
  return sub {
    my $data = shift->{$field} || '';
    return $data ne $val
  };
}

sub op_gt {
  my ($self, $field, $val) = @_;
  return sub {
    my $data = shift->{$field} || '';
    return $data gt $val
  };
}

sub op_lt {
  my ($self, $field, $val) = @_;
  return sub {
    my $data = shift->{$field} || '';
    return $data lt $val
  };
}

sub op_ge {
  my ($self, $field, $val) = @_;
  return sub {
    my $data = shift->{$field} || '';
    return $data ge $val
  };
}

sub op_le {
  my ($self, $field, $val) = @_;
  return sub {
    my $data = shift->{$field} || '';
    return $data le $val
  };
}

sub op_between {
  my ($self, $field, $low, $high) = @_;
  return sub {
    my $data = shift->{$field};
    return $data ge $low && $data le $high;
  };
}

sub op_like {
  my ($self, $field, $val) = @_;
  my ($re) = to_regexp($val);
  return sub {
    my $data = shift->{$field};
    return $data =~ $re;
  }
}

sub op_not {
  my ($self, $pred) = @_;
  my $clause = $self->dispatch_query_op($pred);
  return sub {
    return ! $clause->(shift)
  }
}

sub op_or {
  my ($self, @args) = @_;
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  return sub {
    my $data = shift;
    return any { $_->($data) } @predicates;
  }
}

sub op_and {
  my ($self, @args) = @_;
  my @predicates = map { $self->dispatch_query_op($_) } @args;
  return sub {
    my $data = shift;
    return all { $_->($data) } @predicates;
  }
}

1;

__END__

=for Pod::Coverage::TrustPod add search delete count LOCK_EX LOCK_SH
initialize query translate_query op_eq op_ne op_gt op_lt op_ge op_le
op_between op_like op_not op_or op_and

=head1 SYNOPSIS

    require Metabase::Index::FlatFile;

    my $index = Metabase::Index::FlatFile->new(
      index_file => "$temp_dir/store/metabase.index",
    );

=head1 DESCRIPTION

Flat-file Metabase index.

=head1 USAGE

See L<Metabase::Index>, L<Metabase::Query> and L<Metabase::Librarian>.

=cut
