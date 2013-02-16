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
             country => "  ",
             email2 => "hello",
             country2 => "ciao",
            };

# set the options
my $form = Data::Transpose::Validator->new(stripwhite => 1);

my %sc = (
          email => {
                    validator => {
                                  class => 'Data::Transpose::EmailValid',
                                  options => {
                                              a => 1,
                                              b => 2,
                                             },
                                 },
                    required => 1,
                    options => {
                                stripwhite => 0, # override the global
                               },
                   },
          password => {
                       validator => {
                                     class => 'Data::Transpose::PasswordPolicy',
                                     options => {
                                                 minlength => 10,
                                                 maxlength => 50,
                                                 patternlength => 4,
                                                 mindiffchars => 5,
                                                 disabled => {
                                                              digits => 1,
                                                              mixed => 1,
                                                             }
                                                }
                                    },
                       required => 0,
                      }
         );

$form->prepare(%sc);

# add more, if you want, as an arrayref (will keep the sorting);

$form->prepare([
                {
                 name => "country2",
                 validator => 'String'},
                {
                 name => "email2",
                 validator => "EmailValid"
                }
               ]
              );


# here $clean is meant to be fully validated, or nothing
my $clean = $form->transpose($dirty);

if ($clean) {
    print Dumper($clean);
} else {
    print Dumper($form->errors);
}
print Dumper($form);
