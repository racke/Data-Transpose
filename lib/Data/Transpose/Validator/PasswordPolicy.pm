package Data::Transpose::Validator::PasswordPolicy;
# wrapper for Data::Transpose::PasswordPolicy

use strict;
use warnings;
use base 'Data::Transpose::PasswordPolicy';

sub is_valid {
    my ($self, $password) = @_;
    $self->password($password);
    return $self->SUPER::is_valid;
}

1;
