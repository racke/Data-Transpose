#!perl

use strict;
use warnings;
use Test::More tests => 40;
use Data::Transpose::Validator::TrackingNumber;
use Data::Transpose::Validator;
use Data::Dumper;

my $v = Data::Transpose::Validator::TrackingNumber->new;
my @good = (qw/123456789012
               123456789012abcd
               123456789012abcdefgh
              /);
my @bad = (qw/1234
              1234567890123
              1234567a9012
              123456789012abc=
              *23456789012abcdefgh
              461363/,
           '=a134!@$');

foreach my $n (@good) {
    ok($v->is_valid($n), "$n is valid");
    ok(!$v->error, "no error");
}
foreach my $n (@bad) {
    ok(!$v->is_valid($n), "$n is not valid");
    ok($v->error, "has error") and diag Dumper($v->error);
}

foreach my $n (@good) {
    my $dtv = Data::Transpose::Validator->new();
    $dtv->prepare(tracking_number => { validator => "TrackingNumber" });
    my $form = { tracking_number => $n };
    my $clean = $dtv->transpose($form);
    ok $clean;
    is_deeply($clean, { tracking_number => $n });
}
foreach my $n (@bad) {
    my $dtv = Data::Transpose::Validator->new();
    $dtv->prepare(tracking_number => { validator => "TrackingNumber" });
    my $form = { tracking_number => $n };
    my $clean = $dtv->transpose($form);
    ok !$clean;
    ok($dtv->errors, "Errors found:" . $dtv->packed_errors);    
}

