# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://dev.perl.org/licenses/

package Metabase::Index::FlatFile;
use Moose;
use Moose::Util::TypeConstraints;

use Carp ();
use Fcntl ':flock';
use IO::File ();
use JSON 2 ();

our $VERSION = '0.003';
$VERSION = eval $VERSION;

with 'Metabase::Index';

subtype 'File' 
    => as 'Object' 
        => where { $_->isa( "Path::Class::File" ) && ( (-f && -w) || ! -e ) }
        => message { 'must be a writeable file or must not exist' };
    

coerce 'File' 
    => from 'Str' 
        => via { Path::Class::file($_) };

has 'index_file' => (
    is => 'ro', 
    isa => 'File',
    coerce => 1,
    required => 1, 
);

sub add {
    my ($self, $fact) = @_;
    Carp::confess( "can't index a Fact without a GUID" ) unless $fact->guid;

    my $metadata = $self->clone_metadata( $fact );
    
    my $line = eval {JSON->new->encode($metadata)};
    Carp::confess "Error encoding JSON: $@"
      unless $line;

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

sub search {
    my ($self, %spec) = @_;

    # extract limit and ordering keys
    my $limit = delete $spec{-limit};
    my  %order;
    for my $k ( qw/-asc -desc/ ) {
      $order{$k} = delete $spec{$k} if exists $spec{$k};
    }
    if (scalar keys %order > 1) {
      Carp::confess("Only one of '-asc' or '-desc' allowed");
    }

    my $filename = $self->index_file;
    
    return [] unless -f $filename;
    my $fh = IO::File->new( $filename, "r" )
        or Carp::confess( "Couldn't read from '$filename': $!" );
    $fh->binmode(':raw');

    my @matches;
    flock $fh, LOCK_SH;
    {
        while ( my $line = <$fh> ) {
            my $parsed = JSON->new->decode($line);
            push @matches, $parsed->{'core.guid'} if _match($parsed, \%spec);
        }
    }    
    $fh->close;

    return \@matches;
}

sub exists {
    my ($self, $guid) = @_;
    return scalar @{ $self->search( 'core.guid' => lc $guid ) };
}

sub _match {
    my ($parsed, $spec) = @_;
    for my $k ( keys %$spec ) {
        return unless defined($parsed->{$k}) 
                    && defined($spec->{$k}) 
                    && $parsed->{$k} eq $spec->{$k};
    }
    return 1;
}

1;

=for Pod::Coverage::TrustPod add search exists

=head1 NAME

Metabase::Index::FlatFile - Metabase flat-file index

=head1 SYNOPSIS

    require Metabase::Index::FlatFile;

    my $index = Metabase::Index::FlatFile->new(
      index_file => "$temp_dir/store/metabase.index",
    );

=head1 DESCRIPTION

Flat-file Metabase index.

=head1 USAGE

See L<Metabase::Index> and L<Metabase::Librarian>.

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
