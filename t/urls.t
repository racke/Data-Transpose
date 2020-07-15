use strict;
use warnings;
use Test::More tests => 11;
use Data::Transpose::Validator::URL;

my $v = Data::Transpose::Validator::URL->new;

foreach my $url ('http://test.org',
                 'https://test.org',
                 'http://test.org/',
                 'https://test.org/',
                 'https://test.org/bla-bla',
                 'https://test.org/bla-bla/',
                 'https://test.org/~bla-bla/?q=test&p=x#x%xxx',
                ) {
    ok $v->is_valid($url), "$url is valid";
}
foreach my $url ('random.org',
                'asdfa://test.org',) {
    ok !$v->is_valid($url), "$url is not valid";
}



ok $v->is_valid('http://test.org');
ok $v->is_valid('https://test.org');

