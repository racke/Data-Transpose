package Data::Transpose::Validator::EmailValid;

use strict;
use warnings;
use base 'Data::Transpose::EmailValid';

sub error {
    my $self = shift;
    return $self->reason;
}

1;
