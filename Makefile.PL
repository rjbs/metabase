require 5.006;
use inc::Module::Install;
all_from('lib/Metabase.pm');

requires ('CPAN::DistnameInfo'           => 0       );
requires ('Carp'                         => 0       );
requires ('Compress::Zlib'               => 2       );
requires ('DBD::SQLite'                  => 1       );
requires ('DBI'                          => 1       );
requires ('DBIx::Class'                  => 0       );
requires ('DBIx::Class::Schema'          => 0       );
requires ('Data::GUID'                   => 0       );
requires ('Fcntl'                        => 0       );
requires ('File::Slurp'                  => 9999    );
requires ('IO::File'                     => 0       );
requires ('JSON'                         => 2       );
requires ('JSON::XS'                     => 2       );
requires ('Metabase::Fact'               => 0       );
requires ('Metabase::User::Profile'      => 0       );
requires ('Metabase::User::Secret'       => 0       );
requires ('Moose'                        => 0       );
requires ('Moose::Role'                  => 0       );
requires ('Moose::Util::TypeConstraints' => 0       );
requires ('MooseX::Types::Path::Class'   => 0       );
requires ('Net::Amazon::S3'              => 0       );
requires ('Path::Class'                  => 0       );
requires ('SQL::Abstract'                => 1       );
requires ('SimpleDB::Class::HTTP'        => 0       );
requires ('Try::Tiny'                    => 0       );
requires ('namespace::autoclean'         => 0       );

build_requires('File::Path'                   => 0       );
build_requires('File::Temp'                   => 0.20    );
build_requires('Metabase::Fact::String'       => 0       );
build_requires('Metabase::Report'             => 0       );
build_requires('Test::Exception'              => 0       );
build_requires('Test::Moose'                  => 0       );
build_requires('Test::More'                   => 0.88    );
build_requires('perl'                         => 5.006   );

auto_manifest;
tests_recursive;
extra_tests;

WriteAll;
