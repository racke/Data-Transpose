use strict;
use warnings;
use Test::More tests => 42;
use Data::Transpose::Validator::Subrefs;
use Data::Transpose::Validator::Base;
use Data::Transpose::Validator::String;
use Data::Transpose::Validator::URL;
use Data::Transpose::Validator::NumericRange;

use Data::Dumper;

print "Testing Base\n";
my $v = Data::Transpose::Validator::Base->new;
ok($v->is_valid("string"), "A string is valid");
ok($v->is_valid([]), "Empty array is valid");
ok($v->is_valid({}), "Empty hash is valid");
ok(!$v->is_valid(undef), "undef is not valid");
undef $v;

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
undef $vcr;

print "Testing strings\n";

my $vs = Data::Transpose::Validator::String->new;

ok($vs->is_valid(" "), "Space is valid");
ok($vs->is_valid("\n"), "Newline is valid");
ok(!$vs->error, "No error");
ok(!$vs->is_valid([]), "Arrayref is not valid");
is($vs->error, "Not a string");
undef $vs;

print "Testing urls\n";

my $vu = Data::Transpose::Validator::URL->new;

my @goodurls = ("http://google.com",
                "https://google.com",
                "https://this.doesnt-exists.but-is-valid.co.gov");

my @badurls = ("http://this@.doesnt@-exists.but-is-valid.co.gov",
               "__http://__",
               "http:\\google.com",
               "htp://google.com",
               "http:/google.com",
               "https:/google.com",
              );


foreach my $url (@goodurls) {
    ok($vu->is_valid($url), "$url is valid")
};

foreach my $url (@badurls) {
    ok(!$vu->is_valid($url), "$url is not valid");
    my @errors = $vu->error;
    is_deeply($errors[0], ["badurl",
                           "URL is not correct (the protocol is required)"],
              "Error code for $url is correct" . $vu->error);
}


my $vnr = Data::Transpose::Validator::NumericRange->new(
                                                        min => -90,
                                                        max => 90,
                                                       );

foreach my $val (-90, 10.5, 0, , 80.234, 90) {
    ok($vnr->is_valid($val), "$val is valid");
    if (my $error = $vnr->error) {
        print $error, "\n";
    }
}

foreach my $val (-91, -110.5, 1234, , 181.234, 90.1) {
    ok(!$vnr->is_valid($val), "$val is not valid");
    ok($vnr->error, "$val output an error: " . $vnr->error);
}


