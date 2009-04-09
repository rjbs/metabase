# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package Metabase::Librarian;
use Moose;
use Moose::Util::TypeConstraints;
use Carp ();
use CPAN::DistnameInfo;
use Metabase::Archive;
use Metabase::Index;
use Data::GUID ();

our $VERSION = '0.01';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

has 'archive' => (
    is => 'ro', 
    isa => 'Metabase::Archive',
    required => 1, 
);

has 'index' => (
    is => 'ro', 
    isa => 'Metabase::Index',
    required => 1, 
);

# given fact, store it and return guid; 
sub store {
    my ($self, $fact) = @_;

    # Facts must be assigned GUID at source
    unless ( $fact->guid ) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    # Don't store existing GUIDs; this should never happen, since we're just
    # generating a new one, but... hey, can't be too safe, right?
    if ( $self->index->exists( $fact->guid ) ) {
        Carp::confess("GUID conflicts with an existing object");
    }

    my $fact_struct = $fact->as_struct;
    if ( $self->archive->store( $fact_struct ) 
      && $self->index  ->add  ( $fact ) ) {
        return $fact->guid;
    } else {
        Carp::confess("Error storing or indexing fact with guid: " . $fact->guid);
    }
}

sub search {
    my ($self, %spec) = @_;
    return $self->index->search( %spec );
}

sub extract {
    my ($self, $guid) = @_;
    my $fact_struct = $self->archive->extract( $guid );

    # reconstruct fact meta and extract type to find the class
    my $class = Metabase::Fact->class_from_type(
      $fact_struct->{metadata}{core}{type}[1]
    );

    return $class->from_struct( $fact_struct );
}

sub exists {
    my ($self, $guid) = @_;
    return $self->index->exists( $guid );
}

1;

__END__

=pod

=head1 NAME

Metabase::Librarian - no human would stack books this way

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
