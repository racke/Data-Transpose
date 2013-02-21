package Data::Transpose::Validator::String;

use strict;
use warnings;
use base 'Data::Transpose::Validator::Base';

=head1 NAME

Data::Transpose::Validator::String Validator for strings

=cut

=head2 is_valid

Check with C<ref> if the argument is a string. Return it on success.

=cut

sub is_valid {
    my ($self, $string) = @_;
    $self->reset_errors;
    $self->error(["undefined", "String is undefined"]) unless defined $string;
    $self->error(["hash", "Not a string"]) unless (ref($string) eq '');
    $self->error ? return 0 : return $string;
}

1;
