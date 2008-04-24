# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package CPAN::Metabase::Librarian;
use Moose;
use Moose::Util::TypeConstraints;
use Carp ();
use CPAN::DistnameInfo;
use CPAN::Metabase::Archive;
use CPAN::Metabase::Index;
use Data::GUID ();

our $VERSION = '0.01';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

has 'archive' => (
    is => 'ro', 
    isa => 'CPAN::Metabase::Archive',
    required => 1, 
);

has 'index' => (
    is => 'ro', 
    isa => 'CPAN::Metabase::Index',
    required => 1, 
);

# given fact, store it and return guid; 
sub store {
    my ($self, $fact, $arg) = @_;

    # can only store objects that have not yet been marked submitted
    if ( $fact->is_submitted ) {
        Carp::confess("Can't store a fact that is already marked as submitted");
    }

    Carp::confess("no user_id provided for fact") unless $arg->{user_id};

    my $id = $fact->id;
    my $initials = substr($id,0,1) . '/' . substr($id,0,2);
    my $d = CPAN::DistnameInfo->new( $initials . "/" . $fact->id );

    $fact->guid( Data::GUID->new ),
    $fact->index_meta({
      user_id => $arg->{user_id},
      dist_name    => $d->dist,
      dist_author  => $d->cpanid,
      dist_version => $d->version,
    });

    # Don't store existing GUIDs; this should never happen, since we're just
    # generating a new one, but... hey, can't be too safe, right?
    if ( $self->index->exists( $fact->guid ) ) {
        Carp::confess("GUID conflicts with an existing object");
    }

    if ( $self->archive->store( $fact ) && $self->index->add( $fact ) ) {
        return $fact->guid;
    }
    else {
        Carp::confess("Error storing or indexing fact with guid: " . $fact->guid);
    }
}

sub search {
    my ($self, %spec) = @_;
    return $self->index->search( %spec );
}

sub extract {
    my ($self, $guid) = @_;
    return $self->archive->extract( $guid );
}

1;

__END__

=pod

=head1 NAME

CPAN::Metabase::Librarian - no human would stack books this way

=head1 SYNOPSIS


=head1 DESCRIPTION

Description...

=head1 USAGE

Usage...

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Metabase>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

=over 

=item *

David A. Golden (DAGOLDEN)

=item *

Ricardo J. B. Signes (RJBS)

=back

=head1 COPYRIGHT AND LICENSE

 Portions copyright (c) 2008 by David A. Golden
 Portions copyright (c) 2008 by Ricardo J. B. Signes

Licensed under terms of Perl itself (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a 
copy of the License from http://dev.perl.org/licenses/

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
