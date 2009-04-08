package Metabase::Archive::Schema::Fact;
use strict;
use warnings;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK ResultSourceProxy::Table/);

__PACKAGE__->table('fact');
__PACKAGE__->add_columns(
    guid => {
        data_type   => 'char',
        size        => 36,
        is_nullable => 0,
        is_unique   => 1,
    },
    type => {
        data_type   => 'varchar',
        is_nullable => 0,
    },
    meta => {
        data_type   => 'varchar',
        is_nullable => 0,
    },
    content => {
        data_type   => 'blob',
        is_nullable => 0,
    }
);
__PACKAGE__->set_primary_key('guid');

1;
