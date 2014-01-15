package Data::Transpose::Validator::Group;

use strict;
use warnings;

use base 'Data::Transpose::Validator::Base';

=head1 NAME

Data::Transpose::Validator::Group - Class for grouped field

=head1 SYNOPSIS

=head1 METHODS

=head2 new(name => "name", fields => [$obj1, $obj2, ... ])

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};

    foreach my $f (qw/fields name/) {
        # check for mandatory arg
        die "Missing $f!" unless $args{$f};
        $self->{$f} = $args{$f};
    }

    if (exists $args{equal}) {
        $self->{equal} = $args{equal};
    }
    else {
        $self->{equal} = 1;
    }

    bless $self, $class;
}

=head2 fields

Return the list of the objects set in the constructor. This is read only.

=cut

sub fields {
    return @{ shift->{fields} };
}

=head2 name

Return the name set in the constructor. This is read only.

=cut

sub name {
    return shift->{name};
}


=head2 equal

Set to a true value if the check for equality is needed. Defaults to
true, and so far it's the only use of this module.

=cut

sub equal {
    my $self = shift;
    if (@_) {
        $self->{equal} = shift;
    }
    return $self->{equal};
}

=head2 is_valid

Returns true if the group validates.

=cut


sub is_valid {
    my $self = shift;
    $self->reset_errors;
    my $valid = 1;
    if ($self->equal) {
        $valid = $self->_check_if_fields_are_equal;
    }
    return $valid;
}


sub _check_if_fields_are_equal {
    my $self = shift;
    my @fields = $self->fields;
    my $value;
    my $equal = 1;
    foreach my $f (@fields) {
        # first run the value is undef, so we can't check
        if (defined $value) {
            if ($value ne $f->dtv_value) {
                $equal = 0;
            }
        }
        else {
            $value = $f->dtv_value;
        }
    }
    unless ($equal) {
        $self->error([ not_equal => "Values in group differ!" ]);
    }
    return $equal;
}

1;
