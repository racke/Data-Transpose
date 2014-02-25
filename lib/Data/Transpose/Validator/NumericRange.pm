package Data::Transpose::Validator::NumericRange;
use strict;
use warnings;

use base 'Data::Transpose::Validator::Base';
use Scalar::Util qw/looks_like_number/;

=head1 NAME

Data::Transpose::Validator::NumericRange - Validate numbers in a range

=head1 METHODS

=head2 new(min => $min, max => $max, integer => $bool)

Constructor, setting the minimum, the maximum and the C<integer>
option, which will validate only integers.

=cut


sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
                min => 0,
                max => 0,
                integer => 0,
               };
    foreach my $opt (qw/min max/) {
        die "Wrong range! $opt is mandatory and must be a number!" unless
          looks_like_number($args{$opt});
        $self->{$opt} = $args{$opt};
    }
    $self->{integer} = $args{integer};
    bless $self, $class;
}



=head2 is_valid($number)

The validator. Returns a true value if the number is in the range
passed to the constructor.

=cut


sub is_valid {
    my ($self, $arg) = @_;
    $self->reset_errors;
    $self->error(["undefined", "Not defined"]) unless defined $arg;
    $self->error(["notanumber", "Not a number"]) unless looks_like_number($arg);
    if ($self->wants_integer) {
        $self->error(["notinteger", "Not an integer"]) unless $arg =~ m/^\d+$/;
    }
    return undef if $self->error;
    my $min = $self->min;
    my $max = $self->max;
    if ($arg < $min or $arg > $max) {
        $self->error(["outofrange", "Value is out of range ($min/$max)"])
    }
    $self->error? return 0 : return 1;
}

=head1 INTERNAL ACCESSORS

=head2 min

Return the minimum

=cut

sub min {
    return shift->{min};
}

=head2 min

Return the maximum

=cut


sub max {
    return shift->{max};
}

=head2 wants_integer

Return true if we have to validate only integers

=cut

sub wants_integer {
    return shift->{integer};
}

1;
