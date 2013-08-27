package Data::Transpose::Validator::CreditCard;

use strict;
use warnings;
use base 'Data::Transpose::Validator::Base';

use Business::CreditCard;
# exports 


=head1 NAME

Data::Transpose::Validator::CreditCard - Validator for CC numbers

=head1 DESCRIPTION

This module wraps L<Business::CreditCard> to validate a credit card
number.

=head2 is_valid

Check with C<ref> if the argument is a valid credit card and return it
on success (without whitespace).

=cut

sub is_valid {
    my ($self, $string) = @_;
    $self->reset_errors;
    if (validate($string)) {
        $string =~ s/\s//g;
    }
    else {
        $self->error(["invalid_cc", cardtype($string) . " (invalid)"]);
    }
    $self->error ? return 0 : return $string;
}


=head2 test_cc_numbers

For testing (and validation) purposes, this method returns an hashref
with the test credit card numbers for each provider (as listed by
Business::CreditCard::cardtype()).

=cut

sub test_cc_numbers {
    my $self = shift;
    my $nums = {
                "VISA card" => [
                                '4111111111111111',
                                '4222222222222',
                                '4012888888881881',
                               ],

                "MasterCard" => [
                                 '5555555555554444',
                                 '5105105105105100',
                                ],


                "Discover card" => [ '30569309025904',
                                     '38520000023237',  
                                     '6011111111111117',
                                     '6011000990139424',

                                     # these should be JCB but are reported as JCB
                                     '3530111333300000',
                                     '3566002020360505'
                                   ],

                "American Express card" => [ "378282246310005",
                                             "371449635398431",
                                             "378734493671000",
                                           ],

                "JCB" => [  ],
                "enRoute" => [ ],
                "BankCard" => ['5610591081018250'],
                "Switch" => [ ],
                "Solo" => [ ],
                "China Union Pay" => [ ],
                "Laser" => [ ],
                "Isracard" => [ ],

                "Unknown" => [
                              '5019717010103742',
                              '6331101999990016', # actually it's Switch/Solo
                             ],
               };
    return $nums;
}

# Local Variables:
# tab-width: 4
# End:

1;
