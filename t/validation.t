#!/usr/bin/env perl

use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;

use Test::More tests => 1;


# failing test which should illustrate the usage

my $dirty = {
             email => "i'm\@broken",
             password => "1234",
             country => "  "
            };

# set the options
my $form = Data::Transpose::Validator->new(stripwhite => 1);

my %schema = (
               email => {
                         type => 'EmailValid',
                         required => 1,
                         # option to pass to the class
                         # Data::Transpose::Validator::Type,
                         # which in turn will call is_valid
                         typeoptions => {
                                         option1 => 1,
                                         option2 => 2,
                                        },
                         message => "Failed for those reason"
                        },
               password => {
                            type => 'PasswordPolicy',
                            required => 0,
                            typeoptions => {
                                            a => 1,
                                            b => 2,
                                           },
                            options => {
                                        stripwhite => 0,
                                       }
                           },
             );

$form->prepare(%schema);

# add more, if you want

$form->prepare(country => {type => 'String'});


# here $clean is meant to be fully validated, or nothing
my $clean = $form->transpose($dirty);

if ($clean) {
    print Dumper($clean);
} else {
    print Dumper($form->errors);
}
