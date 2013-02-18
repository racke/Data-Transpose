#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
use Email::Valid;
use Data::Transpose::EmailValid;



my %valid = (
    'uwe@uwevoelker.de'                            => '',
    'racke+test@linuxia.de'                        => '',
    '"Stefan Hornburg (Racke)" <racke@linuxia.de>' => 'racke@linuxia.de',
    'fast_typer@gmail.ocm'                         => 'fast_typer@gmail.com',
    ' pit@bull.de '                                => 'pit@bull.de',
);

my %invalid = (
    'beckyd_sp@yahoo.com/beckydned@gmail.com' => 'rfc822',
    'victorochieng\'679@yahoo.com'            => 'bad_chars',
    'Nour_e;mahdy@yahoo.com'                  => 'rfc822',
    'jneira@academia.usbbog.edu.co.'          => 'rfc822',
    'Ahmed Mohammed6684@gmail.com'            => 'rfc822',
);


my $email = Data::Transpose::EmailValid->new;

while (my ($input, $output) = each %valid) {
    ok($email->is_valid($input), "$input is valid");
    is($email->suggestion || '', $output, "$input -> $output");
}

while (my ($input, $reason) = each %invalid) {
    ok(! $email->is_valid($input), "$input is invalid");
    is($email->reason, $reason, "$input ($reason)");
}

my $v = Email::Valid->new;

SKIP: {
    skip "your dns appears missing or failing to resolve", 2
      unless eval { $v->address(-address=> 'devnull@pobox.com', -mxcheck => 1) };

    if (
        $v->address(-address => 'blort@will-never-exist.pobox.com', -mxcheck => 1)
       ) {
        skip "your dns is lying to you; you must not use mxcheck", 2;
    }
    ok(!$email->is_valid('uwe@uwevoelker-does-not-exist.de'), "Invalid domain");
    is($email->reason, "mxcheck", '@uwevoelker-does-not-exist.de is invalid');
}



done_testing;

