require 5.006;
use inc::Module::Install;
all_from('lib/CPAN/Metabase.pm');

tests_recursive; # why doesn't this work if after "requires"?

requires('Test::More'   => '0.47');
requires('Data::GUID'   => 0);
requires('Moose'        => 0);
requires('File::Temp'   => 0);
requires('File::Slurp'  => 0);
requires('Path::Class'  => 0);
requires('Object::Tiny' => 0);
requires('Test::Exception' => 0);
requires('Moose::Util::TypeConstraints' => 0);

author_tests('xt');

WriteAll;
