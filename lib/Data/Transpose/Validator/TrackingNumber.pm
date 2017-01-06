package Data::Transpose::Validator::TrackingNumber;

use strict;
use warnings;
use Moo;
use Types::Standard qw/ArrayRef Str/;
extends 'Data::Transpose::Validator::Base';

=head1 NAME

Data::Transpose::Validator::TrackingNumber - Validator for Tracking numbers

=head1 SYNOPSIS

  my $v = Data::Transpose::Validator::TrackingNumber->new;
  ok ($v->is_valid('123456789012'));

=head1 DESCRIPTION

This module validates the tracking numbers for commonly used carriers.

=head1 ACCESSORS

=head2 carriers

An arrayref of carriers. See "SUPPORTED CARRIERS" for the list of
available values.

Default to all known carriers.

=head1 METHODS

=head2 is_valid($number)

This is the main method and returns the validated number if valid,
false otherwise.

=head1 SUPPORTED CARRIERS

=over 4

=item DHL

=item UPS

=item Hermes

=item DPD

=back

=cut

has carriers => (is => 'rw',
                 isa => ArrayRef[Str],
                 default => sub { [qw/UPS Hermes DPD DHL/] });

sub is_valid {
    my ($self, $string) = @_;
    $self->reset_errors;
    unless (defined $string) {
        $self->error(["undefined", "String is undefined"]);
        return 0;
    }
    my $valid;

    my %checks = (
                  dpd => qr/([0-9A-Za-z]{14})/x,
                  ups => qr/([0-9A-Za-z]{18})/x,
                  hermes => qr/([0-9A-Za-z]{14})/x,
                  dhl => qr/(
                                [0-9]{12} |
                                [0-9a-zA-Z]{16} |
                                [0-9a-zA-Z]{20}
                            )/x,
                 );
  CARRIER:
    foreach my $carrier (@{$self->carriers}) {
        my $name = lc($carrier);
        $name =~ s/\s/_/g;
        my $re = $checks{$name} or die "Unknown carrier $carrier";
        if ($string =~ m/\A$checks{$name}\z/) {
            $valid = $1;
            last CARRIER;
        }
    }
    if ($valid) {
        return $valid;
    }
    else {
        $self->error(["notrackingnumber",
                      "Tracking number is not valid for " . join(' ', @{$self->carriers})
                     ]);
        return undef;
    }
}

1;
