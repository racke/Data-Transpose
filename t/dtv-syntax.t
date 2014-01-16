use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;
use Test::More tests => 4;

my $dtv;
$dtv = Data::Transpose::Validator->new(requireall => 1);
$dtv->field('email' => "EmailValid");
$dtv->field('password' => 'PasswordPolicy')->disable("username");
$dtv->field('verify' => "String");
$dtv->group(passwords => ("verify", "password"));

my $res = $dtv->transpose({email => 'asdfkl',
                           password => 'abc',
                           verify => 'abc'});

ok(!$res && $dtv->errors);

$res = $dtv->transpose({email => 'marco@linuxia.de',
                        password => 'abc',
                        verify => 'abc'});

ok(!$res && $dtv->errors);



$res = $dtv->transpose({email => 'asdfkl@linuxia.de',
                        password => '3d8931324z9x83;1dZz9',
                        verify => '3d8931324z9x83;1dZz9x'});

is_deeply($dtv->errors, [
                         {
                          'errors' => [
                                       [
                                        'not_equal',
                                        'Values in group differ!'
                                       ]
                                      ],
                          'field' => 'passwords'
                         }
                        ]);



$res = $dtv->transpose({email => 'asdfkl@linuxia.de',
                        password => '3d8931324z9x83;1dZz9',
                        verify =>   '3d8931324z9x83;1dZz9'});

ok($res && !$dtv->errors) or diag Dumper($dtv->errors);
