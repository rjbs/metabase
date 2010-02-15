package Metabase::Index::SimpleDB;
use Moose;
use SimpleDB::Class::HTTP;

with 'Metabase::Index';

has 'aws_access_key_id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'aws_secret_access_key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'domain' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'simpledb' => (
    is      => 'ro',
    isa     => 'SimpleDB::Class::HTTP',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $sdb = SimpleDB::Class::HTTP->new(
            access_key => $self->aws_access_key_id,
            secret_key => $self->aws_secret_access_key
        );
        $sdb->send_request('CreateDomain', { DomainName => $self->domain });
        return $sdb;
    },
);

sub add {
    my ( $self, $fact ) = @_;

    Carp::confess("can't index a Fact without a GUID") unless $fact->guid;

    my %metadata = (
        'core.type'           => $fact->type,
        'core.schema_version' => $fact->schema_version,
        'core.guid'           => lc $fact->guid,
        'core.created_at' =>
            DateTime->from_epoch( epoch => $fact->created_at )->iso8601,
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
                $metadata{"$category.$key"} = $value;
            } elsif ( $type eq 'Num' ) {
                $metadata{"$category.$key"} = $value;
            } else {
                confess "Unknown type $type";
            }
        }
    }

    my $i = 0;
    my @attributes;
    foreach my $key ( keys %metadata ) {
        my $value = $metadata{$key};
        $key =~ s/\./X/g;
        push @attributes,
            "Attribute.$i.Name"    => $key,
            "Attribute.$i.Value"   => $value,
            "Attribute.$i.Replace" => 'true';
        $i++;
    }

    my $response = $self->simpledb->send_request(
        'PutAttributes',
        {   DomainName => $self->domain,
            ItemName   => lc $fact->guid,
            @attributes,
        }
    );
}

sub search {
    my ( $self, %spec ) = @_;

    my @bits;
    foreach my $key ( keys %spec ) {
        my $value = $spec{$key};
        $value =~ s/'/''/g;
        $value =~ s/"/""/g;
        $key   =~ s/\./X/g;
        push @bits, qq{$key='$value'};
    }

    my $sql = 'select id from ' . $self->domain . ' where ' . join( ' and ', @bits );

    my $response = $self->simpledb->send_request(
        'Select',
        {   DomainName       => $self->domain,
            SelectExpression => $sql,
        }
    );

    return [] unless $response->{SelectResult};
    return [] unless $response->{SelectResult}->{Item};
    my @guids;
    if ( ref( $response->{SelectResult}->{Item} ) eq 'HASH' ) {
        @guids = values %{ $response->{SelectResult}->{Item} };
    } else {
        foreach my $item ( @{ $response->{SelectResult}->{Item} } ) {
            push @guids, $item->{Name};
        }
    }
    return \@guids;
}

sub exists {
    my ( $self, $guid ) = @_;

    return scalar @{ $self->search( 'core.guid' => lc $guid ) };
}

1;

__END__

=for Pod::Coverage::TrustPod add search exists

=head1 NAME

Metabase::Index::Solr - Metabase Amazon SimpleDB index

=head1 SYNOPSIS

  require Metabase::Index::SimpleDB;
  Metabase::Index:SimpleDB->new(
    aws_access_key_id => 'XXX',
    aws_secret_access_key => 'XXX',
    domain     => 'metabase',
  );

=head1 DESCRIPTION

Metabase index using Amazon SimpleDB.

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

Leon Brocard (ACME)

=back

=head1 COPYRIGHT AND LICENSE

Portions Copyright (c) 2010 by Leon Brocard

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
