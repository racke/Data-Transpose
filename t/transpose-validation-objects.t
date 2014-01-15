use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;
use Test::More;


my $dtv = Data::Transpose::Validator->new();

$dtv->field(email => { required => 0 })->required(1);
ok $dtv->field('email')->required; # return true
done_testing;
