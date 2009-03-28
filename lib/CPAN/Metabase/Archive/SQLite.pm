# Copyright (c) 2008 by Ricardo Signes. All rights reserved.
# Licensed under terms of Perl itself (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://dev.perl.org/licenses/

package CPAN::Metabase::Archive::SQLite;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;

use CPAN::Metabase::Fact;
use Carp        ();
use Data::GUID  ();
use JSON::XS    ();
use Path::Class ();
use DBI         ();
use DBD::SQLite ();

our $VERSION = '0.01';
$VERSION = eval $VERSION;    # convert '1.23_45' to 1.2345

with 'CPAN::Metabase::Archive';

has 'filename' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
);

has 'dbh' => (
    is      => 'ro',
    isa     => 'DBI::db',
    default => sub {
        my $self     = shift;
        my $filename = $self->filename;
        my $exists = -f $filename;
        my $dbh    = DBI->connect(
            "dbi:SQLite:dbname=$filename",
            "", "",
            {   RaiseError => 1,
                AutoCommit => 1,
            }
        );

        unless ($exists) {
            $dbh->do('PRAGMA auto_vacuum = 1');
            $dbh->do( '
CREATE TABLE archive (
  guid varchar NOT NULL,
  type varchar NOT NULL,
  meta varchar NOT NULL,
  content blob NOT NULL,
  PRIMARY KEY (guid)
)' );
        }
        return $dbh;
    },
);

# given fact, store it and return guid; return
# XXX can we store a fact with a GUID already?  Replaces?  Or error?
# here assign only if no GUID already
sub store {
    my ( $self, $fact ) = @_;
    my $dbh  = $self->dbh;
    my $guid = $fact->guid;
    my $type = $fact->type;

    unless ($guid) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    my $content = $fact->content_as_string;
    my $meta    = JSON::XS->new->encode(
        {   map { ; $_ => $fact->{$_} }
                grep { $_ ne 'content' and $_ ne 'guid' } sort keys %$fact,
        }
    );

    my $sth = $dbh->prepare('INSERT INTO archive VALUES (?, ?, ?, ?)');
    $sth->execute( $guid, $type, $meta, $content );

    return $guid;
}

# given guid, retrieve it and return it
# type is directory path
# class isa CPAN::Metabase::Fact::Subclass
sub extract {
    my ( $self, $guid ) = @_;
    my $dbh = $self->dbh;

    $guid = $guid->as_string if ref $guid;

    my $sth = $dbh->prepare(
        'SELECT type, meta, content FROM archive WHERE guid = ?');
    $sth->execute($guid);
    $sth->bind_columns( \my $type, \my $json, \my $content );
    $sth->fetch;

    my $meta = JSON::XS->new->decode($json);

    # reconstruct fact meta and extract type to find the class
    my $class = CPAN::Metabase::Fact->type_to_class($type);

    # recreate the class
    return $class->new( %$meta,
        content => $class->content_from_string($content), );
}

1;

__END__

=pod

=head1 NAME

CPAN::Metabase::Archive::SQLite - CPAN::Metabase SQLite-based storage

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
