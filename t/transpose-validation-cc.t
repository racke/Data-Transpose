use strict;
use warnings;
use Test::More tests => 102;
use Data::Transpose::Validator::CreditCard;
use Data::Transpose::Validator;
use Data::Dumper;

my $v = Data::Transpose::Validator::CreditCard->new;
ok( $v->is_valid("4111111111111111"), "visa card is valid");
ok(!$v->error, "no error");
ok(!$v->is_valid("4111111112111111"), "Invalid cc");
ok($v->error, "Invalid cc returned an error " . $v->error);
is( $v->is_valid(" 4111 1111 1111 1111 "), "4111111111111111", "CC returned without spaces");

my $test_nums = $v->test_cc_numbers;

foreach my $type (keys  %$test_nums) {
    foreach my $num (@{$test_nums->{$type}}) {
        ok ($v->is_valid($num), "$num is valid");
        $num =~ m/^(\d{8})(\d)(.+)/;
        my ($prefix, $change, $rest) = ($1, $2, $3);
        # change a number to test the failure
        if ($change ne '0') {
            $num = $prefix . '0' . $rest;
        }
        else {
            $num = $prefix . '1' . $rest;
        }
        ok(!$v->is_valid($num), "$num is not valid");
        my $errorstring = $v->error;
        ok($errorstring, $errorstring || "failed");
        ok($errorstring =~ m/^\Q$type\E \(invalid\)/, "$type => $errorstring");
    }
}

diag "Testing types";

$v = Data::Transpose::Validator::CreditCard->new(country => 'DE',
                                                 types => ["visa card",
                                                           "mastercard"]);

$test_nums = $v->test_cc_numbers;

foreach my $type (keys %$test_nums) {
    if ($type eq 'VISA card' or
        $type eq 'MasterCard') {
        foreach my $num (@{$test_nums->{$type}}) {
            ok($v->is_valid($num), "$type $num is valid");
        }
    }
    else {
        foreach my $num (@{$test_nums->{$type}}) {
            ok(!$v->is_valid($num), "$type $num is not valid");
            ok($v->error, "$type $num " . $v->error);
        }
    }
        
}


