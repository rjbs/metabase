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
use JSON::XS ();
use Path::Class ();

our $VERSION = '0.01';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

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
    my ($self, $fact) = @_;

    unless ( $fact->guid ) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    # freeze and write the fact
    File::Slurp::write_file( 
        $self->_guid_path( $fact->guid ), 
        {binmode => ':raw'}, 
        $fact->content_as_bytes
    );
    # write the fact meta info
    File::Slurp::write_file(
        $self->_guid_path( $fact->guid ) . ".meta",
        {binmode => ':raw'},
        JSON::XS->new->encode($fact->core_metadata),
    );

    return $fact->guid;
}

# given guid, retrieve it and return it
# type is directory path
# class isa Metabase::Fact::Subclass
sub extract {
    my ($self, $guid) = @_;
    
    # read the fact
    my $fact_content = File::Slurp::read_file( 
        $self->_guid_path( $guid ),
        binmode => ':raw', 
    );

    # read the fact meta
    my $fact_meta = JSON::XS->new->decode(
      File::Slurp::read_file(
        $self->_guid_path( $guid ) . ".meta",
        binmode => ':raw',
      ),
    );

    for my $key (keys %$fact_meta) {
      $fact_meta->{$key} = $fact_meta->{$key}[1];
    }

    # reconstruct fact meta and extract type to find the class
    my $class = Metabase::Fact->class_from_type($fact_meta->{type});

    # recreate the class
    # XXX should this be from_struct rather than new? -- dagolden, 2009-03-31
    return $class->new(
        %$fact_meta,
        content => $class->content_from_bytes( $fact_content ),
    );
}

sub _guid_path {
    my ($self, $guid) = @_;

    # convert guid from "abc-def-ghi" => "abc/def" as a place to put the file
    my $guid_path = $guid;
    $guid_path =~ s{-}{/}g;
    $guid_path =~ s{/\w+$}{};
    my $fact_path = Path::Class::file( $self->root_dir, $guid_path, $guid );
    $fact_path->dir->mkpath;
    
    return $fact_path->stringify;
}

1;

__END__

=pod

=head1 NAME

Metabase::Archive::Filesystem - Metabase file-based storage

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
