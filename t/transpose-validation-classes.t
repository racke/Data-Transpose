use strict;
use warnings;
use Test::More tests => 4;
use Data::Transpose::Validator::Subrefs;
use Data::Transpose::Validator::Base;
use Data::Transpose::Validator::String;
# use Data::Transpose::Validator::String;


print "Testing Base\n";
my $v = Data::Transpose::Validator::Base->new;
ok($v->is_valid("string"), "A string is valid");
ok($v->is_valid([]), "Empty array is valid");
ok($v->is_valid({}), "Empty hash is valid");
ok(!$v->is_valid(undef), "undef is not valid");


print "Testing coderefs\n";

sub custom_sub {
    my $field = shift;
    return $field
      if $field =~ m/\w/;
    return (undef, "Not a \\w");
}

my $vcr = Data::Transpose::Validator::Subrefs->new( \&custom_sub );

ok($vcr->is_valid("H!"), "Hi! is valid");
ok(!$vcr->is_valid("!"), "! is not");
is($vcr->error, "Not a \\w", "error displayed correctly");






