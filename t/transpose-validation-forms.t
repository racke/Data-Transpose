use strict;
use warnings;
use Test::More tests => 1;
use Data::Transpose::Validator;
use Data::Dumper;

sub get_schema {

    my @schema = (
                  { name => 'institute',
                    validator => "String",
                    required => 1
                  },
                  { name => 'region',
                    validator => "String",
                    required => 1
                  },
                  { name => 'country',
                    validator => "String",
                    required => 1
                  },
                  { name => 'city',
                    validator => 'String',
                    required => 1
                  },
                  { name => 'type',
                    validator => 'String',
                    required => 1
                  },
                  { name => 'mail',
                    validator => 'EmailValid',
                  },
                  { name => 'mail2',
                    validator => 'EmailValid',
                  },
                  { name => 'website',
                    validator => 'URL',
                  },
                  { name => 'latitude',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => -90,
                                              max => 90,
                                             }
                                 }
                  },
                  { name => 'longitude',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => -180,
                                              max => 180,
                                             }
                                 }
                  },
                  { name => 'year',
                    validator => {
                                  class => 'NumericRange',
                                  options => {
                                              min => 1900,
                                              max => 2050,
                                              integer => 1,
                                             }
                                 }
                  },
                  { name => 'open',
                    validator => {
                                  class => 'Set',
                                  options => {
                                              list => [qw/Yes No/],
                                             }
                                 }
                  }
                 );
    return \@schema;
}

# first case: all ok:

sub get_form {
    my $form = {
                institute => " Hey ",
                region => " Europe ",
                country => "Luxemburg",
                city => " L C ",
                type => " fake type ",
               };
    return $form;
}

sub get_expected {
    my $form = {
                institute => "Hey",
                region => "Europe",
                country => "Luxemburg",
                city => "L C",
                type => "fake type",
               };
    return $form;
    
}

      
my ($dtv, $clean, $expected);

$dtv = Data::Transpose::Validator->new();
$dtv->prepare(get_schema());
$clean = $dtv->transpose(get_form());
$expected = get_expected();

is_deeply($clean, $expected, "Transposed is what I expect to be");

print "Testing email\n";




