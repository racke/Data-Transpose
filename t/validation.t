#!/usr/bin/env perl

use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;

# use Test::More tests => 4;


# failing test which should illustrate the usage

my $dirty = {
             email => "i'm\@broken",
             password => "1234",
             country => "  "
            };

my $form = Data::Transpose::Validator->new(stripwhite => 1);


$form->prepare(
               email => {
                         type => 'EmailValid',
                         required => 1,
                                   # option to pass to the class
                                   # Data::Transpose::Validator::Type,
                                   # which in turn will call is_valid
                         options => {
                                     option1 => 1,
                                     option2 => 2,
                                    },
                         message => "Failed for those reason"
                        },
               password => {
                            type => 'PasswordPolicy',
                            required => 0,
                            options => {
                                        a => 1,
                                        b => 2,
                                       }
                           },
              );

# add more

$form->prepare(country => {type => 'String'});


# here $clean is meant to be fully validated, or nothing
my $clean = $form->transpose($dirty);

print Dumper($form);
if ($clean) {
    print Dumper($clean);
}
