use strict;
use warnings;
use Test::More tests => 5;
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
    my %custom = @_;
    my $form = {
                institute => " Hey ",
                region => " Europe ",
                country => "Luxemburg",
                city => " L C ",
                type => " fake type ",
               };
    while (my ($k, $v) = each %custom) {
        $form->{$k} = $v;
    }
    return $form;
}

sub get_expected {
    my %custom = @_;
    my $form = {
                institute => "Hey",
                region => "Europe",
                country => "Luxemburg",
                city => "L C",
                type => "fake type",
               };
    while (my ($k, $v) = each %custom) {
        $form->{$k} = $v;
    }
    return $form;
    
}

      

my ($dtv, $clean, $expected);

$dtv = Data::Transpose::Validator->new();
$dtv->prepare(get_schema());
$clean = $dtv->transpose(get_form());
$expected = get_expected();

is_deeply($clean, $expected, "Transposed is what I expect to be");

print "Testing email\n";


sub test_form {
    my %spec = @_;
    my ($dtv, $form, $clean, $expected);
    $dtv = Data::Transpose::Validator->new(%{$spec{dtvoptions}});
    $dtv->prepare(get_schema());
    $form = get_form(%{$spec{form}});
    $clean = $dtv->transpose($form);
    $expected = get_expected(%{$spec{expected}});

    if ($spec{debug}) {
        print Dumper($form, $clean, $expected)
    };
    
    if ($spec{fail}) {
        is($clean, undef, "transposing returns undef");
        if ($spec{debug}) {
            print Dumper($dtv->errors_as_hashref);
        }
        if ($spec{error_hash}) {
            is_deeply($dtv->errors_as_hashref, $spec{error_hash},
                      "Errors match");
        }
        ok($dtv->errors, $spec{message} . "\n" . $dtv->packed_errors . "\n");
    } else {
        is_deeply($clean, $expected, $spec{message});
    }
}

test_form (
           dtvoptions => {},
           form => {},
           expected => {},
           message => "Plain test",
           fail => 0,
          );

test_form (
           dtvoptions => {},
           form => {mail => "invalid+ciao\@asdf_daslf"},
           expected => {},
           message => "Invalid email",
           error_hash => { mail => [ 'fqdn' ] },
           fail => 1,
           debug => 1,
          );



