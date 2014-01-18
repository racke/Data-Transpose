use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Transpose',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Data/Transpose.pm',
    ABSTRACT_FROM       => 'lib/Data/Transpose.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Warn' => 0,
        'Email::Valid' => 0,
        'Try::Tiny' => 0,
        'Module::Load' => 0,
        'Scalar::Util' => 0,
        'Business::CreditCard' => 0.32,
    },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/racke/Data-Transpose',
            bugtracker  => 'https://github.com/racke/Data-Transpose/issues',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Transpose-*' },
);
