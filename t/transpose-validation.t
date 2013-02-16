#!/usr/bin/env perl

use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;

use Test::More tests => 4;

print "Testing a simple case\n";

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


my $form = {
            email => ' ciao@hello.it ',
            password => ' 4Horses5_Staple ',
            country => ' Germany ',
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

print Dumper($form);

my $clean = $dtv->transpose($form);
ok($clean, "Transposing returned the clean hash");
is_deeply($clean, $expected,
          "The transposing stripped the leading/trailing whitespace");

print ($dtv->packed_errors) unless $clean;


