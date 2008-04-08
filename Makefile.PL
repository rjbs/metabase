require 5.006;
use inc::Module::Install;
all_from('lib/CPAN/Metabase.pm');

requires('Test::More' => '0.47');
requires('Data::UUID' => 0);
requires('Moose' => 0);
requires('Moose::Util::TypeConstraints' => 0);
requires('Test::Exception' => 0);
requires('File::Temp' => 0);
requires('File::Slurp' => 0);
requires('Path::Class' => 0);
requires('Object::Tiny' => 0);

tests_recursive;
