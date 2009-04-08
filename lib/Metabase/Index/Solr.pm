package Metabase::Index::Solr;
use Moose;
use WebService::Solr;

with 'Metabase::Index';

has 'solr' => (
    is      => 'ro',
    isa     => 'WebService::Solr',
    lazy    => 1,
    default => sub {
        WebService::Solr->new( undef, { autocommit => 0 } );
    },
);

sub add {
    my ( $self, $fact ) = @_;
    my $solr = $self->solr;

    Carp::confess("can't index a Fact without a GUID") unless $fact->guid;

    my %metadata = (
        'core.type_s'           => $fact->type,
        'core.schema_version_i' => $fact->schema_version,
        'core.guid_s'           => $fact->guid,
        'core.created_at_i'     => $fact->created_at,
    );

    for my $category (qw(content resource)) {
        my $method = "$category\_metadata";
        my $data = $fact->$method || {};

        for my $key ( keys %$data ) {

          # I'm just starting with a strict-ish set.  We can tighten or loosen
          # parts of this later. -- rjbs, 2009-03-28
            die "invalid metadata key" unless $key =~ /\A[-_a-z0-9.]+\z/;
            my ( $type, $value ) = @{ $data->{$key} };
            if ( $type eq 'Str' ) {
                $metadata{"$category.$key\_s"} = $value;
            } elsif ( $type eq 'Num' ) {
                $metadata{"$category.$key\_i"} = $value;
            } else {
                confess "Unknown type $type";
            }
        }
    }

    my $doc = WebService::Solr::Document->new;
    $doc->add_fields(%metadata);
    $solr->add($doc);
    $solr->commit;

    # $solr->optimize;
}

sub search {
    my ( $self, %spec ) = @_;
    my $solr = $self->solr;

    my $query;
    if ( $spec{'core.guid'} ) {
        $query = "core.guid_s:" . $spec{'core.guid'};
    } elsif ( $spec{'core.type'} ) {
        $query = "core.type_s:" . $spec{'core.type'};
    } else {
        warn "other query";
        return [];
    }

    my @matches;
    my $response = $solr->search($query);
    for my $doc ( $response->docs ) {
        push @matches, $doc->value_for('core.guid_s');
    }

    return \@matches;
}

sub exists {
    my ( $self, $guid ) = @_;

    return scalar @{ $self->search( 'core.guid' => $guid ) };
}

1;
