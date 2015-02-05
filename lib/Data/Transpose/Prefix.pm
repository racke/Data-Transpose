package Data::Transpose::Prefix;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Prefix - prefix subclass for Data::Transpose

=head1 SYNOPSIS

=cut

use Moo;

extends 'Data::Transpose';

use Data::Transpose::Prefix::Field;

has prefix => (
    is => 'ro',
    required => 1,
);

sub field {
    my ($self, $name) = @_;
    my ($object);

    $object = Data::Transpose::Prefix::Field->new(
        name => $name,
        prefix => $self->prefix,
    );

    push @{$self->_fields}, $object;

    return $object;
};

1;
