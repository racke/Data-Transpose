package Data::Transpose::Validator::TrackingNumber;

use strict;
use warnings;
use Moo;
extends 'Data::Transpose::Validator::Base';

=head1 NAME

Data::Transpose::Validator::TrackingNumber - Validator for Tracking numbers

=head1 SYNOPSIS

  my $v = Data::Transpose::Validator::TrackingNumber->new;
  ok ($v->is_valid('123456789012'));

=head1 DESCRIPTION

This module validates the tracking numbers for commonly used carriers.

=head1 METHODS

=head2 is_valid($number)

This is the main method and returns the validated number if valid,
false otherwise.

=head1 SUPPORTED CARRIERS

=over 4

=item DHL

=back

=cut


sub is_valid {
    my ($self, $string) = @_;
    $self->reset_errors;
    unless (defined $string) {
        $self->error(["undefined", "String is undefined"]);
        return 0;
    }
    if ($string =~ m/\A
                     (
                         # DHL
                         [0-9]{12} |
                         [0-9a-zA-Z]{16} |
                         [0-9a-zA-Z]{20}
                     )\z/x) {
        return $1;
    }
    else {
        $self->error(["notrackingnumber",
                      "Tracking number is not valid"]);
        return undef;
    }
}

1;
