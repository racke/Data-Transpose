package Data::Transpose::Validator::Set;
use strict;
use warnings;

use base 'Data::Transpose::Validator::Base';
use Scalar::Util qw/looks_like_number/;

=head1 NAME

Data::Transpose::Validator::Set - Validate a string inside a set of values

=head1 METHODS

=head2 new(list => \@list, multiple => 1)

Constructor to set the list in which the value to be validated must be
present.

=cut


sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
                list => [],
                multiple => 0,
               };
    unless ($args{list} and (ref($args{list}) eq 'ARRAY')) {
        die "Fatal: you must set the list in the constructor\n" 
    }
    $self = \%args;
    bless $self, $class;
}



=head2 is_valid($value, [ $value, $value, ... ] )

The validator. Returns a true value if the value (or the values)
passed are all present in the set. Multiple values validate only if
the C<multiple> option is set in the constructor. It also accept an
arrayref as single argument, if the C<multiple> option is set.

=cut


sub is_valid {
    my ($self, @args) = @_;
    $self->reset_errors;
    my @input;
    if (@args == 1) {
        my $arg = shift @args;
        if (ref($arg) eq 'ARRAY') {
            if ($self->wants_multiple) {
                push @input, @$arg
            }
            else {
                $self->error([nomulti => "No multiple values are allowed"])
            }
        }
        elsif (ref($arg) ne '') {
            die "Bad argument\n";
        }
        else {
            push @input, $arg;
        }
    }
    elsif (@args > 1) {
        if ($self->wants_multiple) {
            push @input, @args;
        } else {
            $self->error([nomulti => "No multiple values are allowed"]);
        }
    }
    else {
        $self->error([noinput => "No value passed"]);
    }
    return undef if $self->error;
    return $self->_check_set(@input);

}

sub _check_set {
    my ($self, @input) = @_;
    my %list = $self->list;
    foreach my $val (@input) {
        $self->error(["missinginset", "No match in the allowed values"])
          unless exists $list{$val};
    }
    $self->error ? return 0 : return 1;
}


=head1 INTERNAL METHODS

=head2 wants_multiple

Accessor to the C<multiple> option

=cut

sub wants_multiple {
    return shift->{multiple}
}

=head2 list

Accessor to the list of values, as an hash.

=cut

sub list {
    my $self = shift;
    my %list;
    foreach my $e (@{$self->{list}}) {
        $list{$e} = 1;
    }
    return %list;
}


1;
