require 5.006;
use inc::Module::Install;
all_from('lib/Metabase.pm');

requires('Metabase::Fact' => 0);

requires('Test::More'   => '0.47');
requires('JSON::XS'     => 0);
requires('Data::GUID'   => 0);
requires('Moose'        => 0);
requires('File::Temp'   => 0);
requires('File::Slurp'  => 0);
requires('Path::Class'  => 0);
requires('Test::Exception' => 0);
requires('DBI'          => 0);
requires('DBD::SQLite'  => 0);
requires('DBIx::Class'  => 0);
requires('Moose::Util::TypeConstraints' => 0);
requires('MooseX::Types::Path::Class' => 0);

tests_recursive;
extra_tests;

WriteAll;
