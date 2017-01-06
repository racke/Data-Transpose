#!perl

use strict;
use warnings;
use Test::More tests => 86;
use Data::Transpose::Validator::TrackingNumber;
use Data::Transpose::Validator;
use Data::Dumper;

my $v = Data::Transpose::Validator::TrackingNumber->new(carriers => [qw/DHL/]);
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
    $dtv->prepare(tracking_number => { validator => {
                                                     class => "TrackingNumber",
                                                     options => { carriers => [qw/DHL UPS/] },
                                                    }
                                     });
    my $form = { tracking_number => $n };
    my $clean = $dtv->transpose($form);
    ok $clean;
    is_deeply($clean, { tracking_number => $n });
}
foreach my $n (@bad) {
    my $dtv = Data::Transpose::Validator->new();
    $dtv->prepare(tracking_number => { validator => {
                                                     class => "TrackingNumber",
                                                     options => { carriers => [qw/DHL UPS DPD/] },
                                                    }
                                     });
    my $form = { tracking_number => $n };
    my $clean = $dtv->transpose($form);
    ok !$clean;
    ok($dtv->errors, "Errors found:" . $dtv->packed_errors);
    like $dtv->packed_errors, qr{dhl}i;
    unlike $dtv->packed_errors, qr{hermes}i;
}

my $vstrict = Data::Transpose::Validator::TrackingNumber->new(carriers => [qw/UPS/]);

foreach my $n (@good, @bad) {
    ok(!$vstrict->is_valid($n), "$n is not valid");
    ok($v->error, "has error") and diag Dumper($v->error);
}

my %carriers = (
                dhl    => 'L2345678901234567890',
                ups    => 'L23456789012345678',
                hermes => 'L2345678901234',
                dpd    => 'L2345678901234',
               );
foreach my $carrier (keys %carriers) {
    my $validator = Data::Transpose::Validator::TrackingNumber->new(carriers => [uc($carrier)]);
    ok $validator->is_valid($carriers{$carrier}),
      "$carriers{$carrier} is valid for $carrier";
    ok !$validator->is_valid($carriers{$carrier} . 'x'),
      "$carriers{$carrier}x is not valid for $carrier";
    ok($validator->error, "has error") and diag Dumper($validator->error);
}
