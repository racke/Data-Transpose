#!/usr/bin/env perl

use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;

use Test::More tests => 20;

my $dtv = Data::Transpose::Validator->new();

my $schema = [
              {
               name => "email",
               validator => 'EmailValid',
              },
              {
               name => "password",
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
               name => "country",
               validator => sub {
                   my $value = shift;
                   return 1 if $value =~ m/\w/;
               }
              }
             ];


print "Testing a simple form. The unknown option is to the default, so submit will be ignored\n";

my $form = {
            email => ' ciao@hello.it ',
            password => ' 4Horses5_Staple ',
            country => ' Germany ',
            submit => 1,
            };

my $expected = {
                email => 'ciao@hello.it',
                password => '4Horses5_Staple',
                country => 'Germany',
               };


$dtv->prepare($schema);
my $clean = $dtv->transpose($form);
ok($clean, "Transposing returned the clean hash");
is_deeply($clean, $expected,
          "The transposing stripped the leading/trailing whitespace");

$form->{password} = '      horse_stalple   ';
$expected->{password} = 'horse_stalple';

# print Dumper($form);

my $otherclean = $dtv->transpose($form);
ok($otherclean, "Transposing returned the clean hash");
is_deeply($otherclean, $expected,
          "The transposing stripped the leading/trailing whitespace");

print ($dtv->packed_errors) unless $clean;

print "Check the default options\n";

is($dtv->option("requireall"), 0, "Requireall is set to false");
$dtv->option(requireall => 1);
is($dtv->option("requireall"), 1, "Requireall now is set to true");

print "Check option for individual fields\n";

is($dtv->option_for_field(stripwhite => "email"), 1,
   "stripwhite for email is true");

$schema->[0]->{options}->{stripwhite} = 0;
$dtv = Data::Transpose::Validator->new(stripwhite => 1);
$dtv->prepare($schema);
is($dtv->option_for_field(stripwhite => "email"), 0,
   "stripwhite for email is false now");

my @objoptions = sort (qw/missing stripwhite requireall unknown/);
my @optionstocheck = $dtv->options;
is_deeply(\@objoptions, \@optionstocheck, "Checking ->options");

eval {
    $dtv->field({}, 1);
};
ok($@, "Passing something which is not a scalar crashes the thing");

my @sortedfields = $dtv->_sorted_fields;
my @expected = qw/email password country/;
is_deeply(\@sortedfields, \@expected, "fields are kept sorted internally");

ok(!$dtv->field_is_required("email"), "email is not required");
# tweak the schema
$dtv->option(requireall => 1);
ok($dtv->field_is_required("email"), "Now it is ");
$dtv->option(requireall => 0);
ok(!$dtv->field_is_required("email"), "Now it's not");
$schema->[0]->{required} = 1;

eval {
    $dtv->prepare($schema);
};

ok($@, "Overwriting the schema raises an exception");

$dtv = Data::Transpose::Validator->new(stripwhite => 1);
$dtv->prepare($schema);
ok($dtv->field_is_required("email"), "Now it is ");


$dtv = Data::Transpose::Validator->new();
$dtv->field(email => { required => 1 });
ok ($dtv->field("email")->required, "Field email set with field");

eval {
    $dtv->field;
};
ok ($@, "DTV died on field without arguments");


# reset all

my %sch = (email => {validator => "EmailValid",
                     required => 1,
                    },
           password => {validator => "PasswordPolicy",
                        required => 0},
           username => {required => 1});

# use default
my $validator = Data::Transpose::Validator->new();
$validator->prepare(%sch);
$form = {
            email => 'melmothx@gmail.com',
            username => 'melmothx',
            password => "",
           };

my $cleaned = $validator->transpose($form);

is_deeply($form, $cleaned, "Form is valid");


delete $form->{password};
$cleaned = $validator->transpose($form);

my $expectedform = { %$form };
# $expectedform->{password} = undef;

is_deeply($cleaned, $expectedform, "fields not passed but not required
will be undefined but preset)");

print Dumper($form, $expectedform);




