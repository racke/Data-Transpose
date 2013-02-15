package Data::Transpose::Validator::PasswordPolicy;
# wrapper for Data::Transpose::PasswordPolicy

use strict;
use warnings;
use base 'Data::Transpose::Validator::Base';
use Data::Transpose::PasswordPolicy;

sub is_valid {
    return 1;
}

1;
