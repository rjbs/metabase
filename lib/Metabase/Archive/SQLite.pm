use 5.006;
use strict;
use warnings;

package Metabase::Archive::SQLite;
# ABSTRACT: Metabase storage using SQLite
# VERSION

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;

use Metabase::Fact;
use Carp        ();
use Data::GUID  ();
use JSON 2      ();
use Path::Class ();
use DBI         1 ();
use DBD::SQLite 1 ();
use Compress::Zlib 2 qw(compress uncompress);
use SQL::Translator 0.11006 (); # required for deploy()
use Metabase::Archive::Schema;

with 'Metabase::Archive';

has 'filename' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
);

has 'compressed' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has 'synchronous' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'schema' => (
    is      => 'ro',
    isa     => 'Metabase::Archive::Schema',
    lazy    => 1,
    default => sub {
        my $self     = shift;
        my $filename = $self->filename;
        my $exists   = -f $filename;
        my $schema   = Metabase::Archive::Schema->connect(
            "dbi:SQLite:$filename",
            "", "",
            {   RaiseError => 1,
                AutoCommit => 1,
            },
        );
        return $schema;
    },
);

sub initialize {
  my ($self, @fact_classes) = @_;
  $self->schema->deploy unless -e $self->filename;
  $self->schema->storage->dbh_do(
    sub {
      my ($storage,$dbh) = @_;
      my $toggle = $self->synchronous ? "ON" : "OFF";
      $dbh->do("PRAGMA synchronous = $toggle");
    }
  );
  return;
}

# given fact, store it and return guid; return
# XXX can we store a fact with a GUID already?  Replaces?  Or error?
# here assign only if no GUID already
sub store {
    my ( $self, $fact_struct ) = @_;
    my $guid = lc $fact_struct->{metadata}{core}{guid};
    my $type = $fact_struct->{metadata}{core}{type};

    unless ($guid) {
        Carp::confess "Can't store: no GUID set for fact\n";
    }

    my $content = $fact_struct->{content};
    my $json    = eval { JSON->new->ascii->encode($fact_struct->{metadata}{core}) };
    Carp::confess "Couldn't convert to JSON: $@"
      unless $json;

    if ( $self->compressed ) {
        $json    = compress($json);
        $content = compress($content);
    }

    $self->schema->resultset('Fact')->create(
        {   guid    => $guid,
            type    => $type,
            meta    => $json,
            content => $content,
        }
    );

    return $guid;
}

# given guid, retrieve it and return it
# type is directory path
# class isa Metabase::Fact::Subclass
sub extract {
    my ( $self, $guid ) = @_;
    my $schema = $self->schema;

    my $fact = $schema->resultset('Fact')->find(lc $guid);
    return undef unless $fact;

    my $type    = $fact->type;
    my $json    = $fact->meta;
    my $content = $fact->content;

    if ( $self->compressed ) {
        $json    = uncompress($json);
        $content = uncompress($content);
    }

    my $meta = JSON->new->ascii->decode($json);

    # reconstruct fact meta and extract type to find the class
    my $class = Metabase::Fact->class_from_type($type);

    return { 
      content => $content, 
      metadata => {
        core => $meta
      },
    };
}

1;

__END__

=for Pod::Coverage::TrustPod store extract

=head1 SYNOPSIS

  require Metabase::Archive::SQLite;

  $archive = Metabase::Archive::SQLite->new(
    filename => $sqlite_file,
  ); 

=head1 DESCRIPTION

Store facts in a SQLite database.

=head1 USAGE

See L<Metabase::Archive> and L<Metabase::Librarian>.

TODO: document optional C<compressed> option (default 1) and
C<schema> option (sensible default provided).

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 COPYRIGHT AND LICENSE

 Portions Copyright (c) 2008-2009 by Leon Brocard

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
