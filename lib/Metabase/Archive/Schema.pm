use 5.006;
use strict;
use warnings;

package Metabase::Archive::Schema;
use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/Fact/);

1;
