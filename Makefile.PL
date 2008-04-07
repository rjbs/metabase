require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile (
    'PL_FILES' => {},
    'INSTALLDIRS' => 'site',
    'NAME' => 'CPAN::Metabase',
    'EXE_FILES' => [],
    'VERSION_FROM' => 'lib/CPAN/Metabase.pm',
    'PREREQ_PM' => {
        'Test::More' => '0.47',
        'Data::UUID' => 0,
        'Moose' => 0,
        'Moose::Util::TypeConstraints' => 0,
        'Test::Exception' => 0,
        'File::Temp' => 0,
        'File::Slurp' => 0,
        'Path::Class' => 0,
    }
);
