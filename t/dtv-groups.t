use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;
use Test::More;

# typical usage

# Can we do something like this (from Input::Validator) with Data::Transpose::Validator?
# 
# # Groups
# $validator->field([qw/password confirm_password/])
#   ->each(sub { shift->required(1) });
# $validator->group('passwords' => [qw/password confirm_password/])->equal;

sub get_schema {
    my @schema = (
                  {
                   name => 'username',
                   validator => 'String',
                   required => 1,
                  },
                  {
                   name => 'password',
                   validator => {
                                 class => 'Data::Transpose::PasswordPolicy',
                                 absolute => 1,
                                 options => {
                                             minlength => 10,
                                             maxlength => 50,
                                             patternlength => 4,
                                             mindiffchars => 5,
                                             disabled => {
                                                          digits => 1,
                                                          mixed => 1,
                                                          username => 1,
                                                         }
                                            }
                                }
                  },
                  {
                   name => 'confirm_password',
                   required => 1,
                   validator => 'String',
                  },
                  {
                   name => 'passwords',
                   validator => 'Group',
                   fields => [
                              qw/password confirm_password/,
                             ],
                   equal => 1,
                  },
                 );
    return \@schema;
}

my $dtv = Data::Transpose::Validator->new;

$dtv->field(password => { required => 1 });
$dtv->field(confirm_password => { required => 1 });
$dtv->group(passwords => "password", "confirm_password")->equal;

my $form = { password => 'a',
             confirm_password => 'b' };

my $res = $dtv->transpose($form);

ok(!$res);
ok($dtv->packed_errors) and diag $dtv->packed_errors;

$res = $dtv->transpose({ password => 'a', confirm_password => 'a' });
ok ($res);
ok (!$dtv->errors);

$res = $dtv->transpose({ password => 'a', confirm_password => 'c' });
ok (!$res);
ok ($dtv->errors);
ok ($dtv->packed_errors);

$res = $dtv->transpose( { password => '', confirm_password => 'c' });
ok (!$res);
ok ($dtv->errors);
diag $dtv->packed_errors;


$dtv = Data::Transpose::Validator->new;
$dtv->field(password => { required => 1 });
$dtv->field(confirm_password => { required => 1 });
$dtv->group(passwords => "password", "confirm_password")->equal(0);

$res = $dtv->transpose({password => "a", confirm_password => "c" });
ok($res);
my $group = $dtv->group('passwords');
ok($group, "Object retrieved");
ok($group->warnings, "Warning found") and diag $group->warnings;

# even if equal, the validation doesn't pass because of the empty strings
$res = $dtv->transpose({password => "", confirm_password => "" });
ok(!$res);
ok($dtv->errors) and diag join("\n", $dtv->packed_errors);

done_testing;
