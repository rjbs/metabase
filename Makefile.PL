require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile (
    'PL_FILES' => {},
    'INSTALLDIRS' => 'site',
    'NAME' => 'CPAN::Metabase',
    'EXE_FILES' => [],
    'VERSION_FROM' => 'lib/CPAN/Metabase.pm',
    'PREREQ_PM' => {
        'Test::More' => '0.47'
    }
);
