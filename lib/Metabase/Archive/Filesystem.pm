# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package Metabase::Archive::Filesystem;
use Moose;
use Moose::Util::TypeConstraints;

use Metabase::Fact;
use Carp ();
use Data::GUID ();
use File::Slurp ();
use JSON 2 ();
use Path::Class ();

our $VERSION = '0.003';
$VERSION = eval $VERSION;

with 'Metabase::Archive';

subtype 'ExistingDir' 
    => as 'Object' 
        => where { $_->isa( "Path::Class::Dir" ) && -d "$_" };

coerce 'ExistingDir' 
    => from 'Str' 
        => via { Path::Class::dir($_) };

has 'root_dir' => (
    is => 'ro', 
    isa => 'ExistingDir',
    coerce => 1,
    required => 1, 
);

# given fact, store it and return guid; return
# XXX can we store a fact with a GUID already?  Replaces?  Or error?
# here assign only if no GUID already
sub store {
    my ($self, $fact_struct) = @_;

    my $guid = $fact_struct->{metadata}{core}{guid};
    unless ( $guid ) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    # freeze and write the fact
    File::Slurp::write_file( 
        $self->_guid_path( $guid ), 
        {binmode => ':raw'}, 
        JSON->new->encode($fact_struct),
    );

    return $guid;
}

# given guid, retrieve it and return it
# type is directory path
# class isa Metabase::Fact::Subclass
sub extract {
    my ($self, $guid) = @_;
    
    # read the fact
    my $fact_struct = JSON->new->decode(
      File::Slurp::read_file(
        $self->_guid_path( $guid ),
        binmode => ':raw',
      ),
    );

    return $fact_struct;
}

sub _guid_path {
    my ($self, $guid) = @_;

    # convert guid from "abc-def-ghi" => "abc/def" as a place to put the file
    my $guid_path = lc $guid;
    $guid_path =~ s{-}{/}g;
    $guid_path =~ s{/\w+$}{};
    my $fact_path = Path::Class::file( $self->root_dir, $guid_path, $guid );
    $fact_path->dir->mkpath;
    
    return $fact_path->stringify;
}

1;

__END__

=pod

=for Pod::Coverage::TrustPod store extract

=head1 NAME

Metabase::Archive::Filesystem - Metabase filesystem-based storage

=head1 SYNOPSIS

  require Metabase::Archive::Filesystem;

  $archive = Metabase::Archive::Filesystem->new(
    root_dir => $storage_directory
  ); 

=head1 DESCRIPTION

Store facts as files in the filesystem, hashed into a directory tree by GUID to
manage the number of files in any particular directory.

=head1 USAGE

See L<Metabase::Archive> and L<Metabase::Librarian>.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase>

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

 Portions Copyright (c) 2008-2009 by David A. Golden
 Portions Copyright (c) 2008-2009 by Ricardo J. B. Signes

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
