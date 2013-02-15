package Data::Transpose::Validator::Base;


use strict;
use warnings;

sub new {
    my $class = shift;
    my %options = @_;
    my $self = \%options;
    bless $self, $class;
    return $self;
}

sub is_valid {
    return 1
}

sub errors {
    return
}

1;
