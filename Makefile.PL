require 5.006;
use inc::Module::Install;
all_from('lib/Metabase.pm');

requires      ('CPAN::DistnameInfo'           => 0.09    );
requires      ('Carp'                         => 0       );
requires      ('Compress::Zlib'               => 2.024   );
requires      ('DBD::SQLite'                  => 1.25    );
requires      ('DBI'                          => 1.609   );
requires      ('DBIx::Class'                  => 0.08115 );
requires      ('Data::GUID'                   => 0.045   );
requires      ('Fcntl'                        => 1.06    );
requires      ('File::Slurp'                  => 9999.13 );
requires      ('IO::File'                     => 0       );
requires      ('JSON'                         => 2.17    );
requires      ('JSON::XS'                     => 2.26    );
requires      ('Metabase::Fact'               => 0.003   );
requires      ('Metabase::User::Profile'      => 0.003   );
requires      ('Metabase::User::Secret'       => 0.003   );
requires      ('Moose'                        => 0.93    );
requires      ('Moose::Role'                  => 0.93    );
requires      ('Moose::Util::TypeConstraints' => 0.93    );
requires      ('MooseX::Types::Path::Class'   => 0.05    );
requires      ('Net::Amazon::S3'              => 0.52    );
requires      ('Path::Class'                  => 0.17    );
requires      ('SQL::Abstract'                => 1.61    );
requires      ('SimpleDB::Class::HTTP'        => 0.0802  );
requires      ('Try::Tiny'                    => 0.04    );
requires      ('base'                         => 2.14    );
requires      ('namespace::autoclean'         => 0.09    );

build_requires('File::Path'                   => 0       );
build_requires('File::Temp'                   => 0.20    );
build_requires('Metabase::Fact::String'       => 0.003   );
build_requires('Metabase::Report'             => 0.003   );
build_requires('Test::Exception'              => 0.27    );
build_requires('Test::Moose'                  => 0.93    );
build_requires('Test::More'                   => 0.88    );
build_requires('perl'                         => 5.006   );

auto_manifest;
tests_recursive;
extra_tests;

WriteAll;
