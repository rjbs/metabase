use 5.006;
use strict;
use warnings;

package Metabase::Test::Archive::Null;
# ABSTRACT: Metabase storage that discards all data
# VERSION

use Moose;

use Carp ();
use Data::Stream::Bulk::Nil;

with 'Metabase::Archive';

sub initialize { }

# given fact, discard it and return guid
sub store {
    my ($self, $fact_struct) = @_;

    my $guid = $fact_struct->{metadata}{core}{guid};
    unless ( $guid ) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    # do nothing except return
    return $guid;
}

# we discard, so can't ever extract
sub extract {
  die "unimplemented";
}

# does nothing
sub delete {
  my ($self, $guid) = @_;
  return $guid;
}

# we have nothing to return
sub iterator {
  return Data::Stream::Bulk::Nil->new;
}

1;

__END__

=for Pod::Coverage
  store extract delete iterator initialize

=head1 SYNOPSIS

  require Metabase::Test::Archive::Null;
  $archive = Metabase::Test::Archive::Null->new;

=head1 DESCRIPTION

Discards all facts to be stored.  For testing only, obviously.

=cut
