require 5.006;
use inc::Module::Install;
all_from('lib/CPAN/Metabase.pm');

requires('CPAN::Metabase::Fact' => 0);

requires('Test::More'   => '0.47');
requires('Data::GUID'   => 0);
requires('Moose'        => 0);
requires('File::Temp'   => 0);
requires('File::Slurp'  => 0);
requires('Path::Class'  => 0);
requires('Object::Tiny' => 0);
requires('Test::Exception' => 0);
requires('Moose::Util::TypeConstraints' => 0);
build_requires('MooseX::Singleton');

tests_recursive;
extra_tests;

WriteAll;
