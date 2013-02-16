package Data::Transpose::Validator;

use strict;
use warnings;
use Module::Load;

=head2 new

The constructor. It accepts a hash as argument, with options:

C<stripwhite>


=cut 


sub new {
    my ($class, %options) = @_;
    my $self = {};
    my %defaults = (
                    stripwhite => 0,
                   );
    # slurp the options, overwriting the defaults
    while (my ($k, $v) = each %defaults) {
        if (exists $options{$k}) {
            $defaults{$k} = $options{$k}
        }
    }
    $self->{options} = \%defaults;
    bless $self, $class;
}

=head2 prepare

C<prepare> takes a hash and pass the key/value pairs to C<field> 

=cut


sub prepare {
    my $self = shift;
    my %fields = @_;
    while (my ($k, $v) = each %fields) {
        $self->field($k, $v)
    }
}

=head2 field

This accessor sets the various fields and their options.

=cut

sub field {
    my ($self, $field, $args) = @_;

    # initialize
    $self->{fields} = {} unless exists $self->{fields};

    # validate the field
    unless ($field and (ref($field) eq '')) {
        die "Wrong usage, argument to field is mandatory\n" 
    };

    #  validate the args and store them
    if ($args and (ref($args) eq 'HASH')) {
        $self->{fields}->{$field} = $args;
    }
    
    return $self->{fields}->{$field};
}

=head2 transpose

The main method. It validates the hash and return a validated one or
nothing if there were errors.

=cut


sub transpose {
    my ($self, $hash) = @_;
    foreach my $k (keys %$hash) {
        my $obj = $self->_build_object($k);
        unless ($obj->is_valid($hash->{$k})) {
            my @errors = $obj->error;
            $self->errors($k, \@errors)
        }
    }
    # do other stuff, check the options, filter, set  and return it
    return if $self->errors;
    return $hash;
}


=head2 error

Accessor to set or retrieve the errors.

=cut

sub errors {
    my ($self, $field, $error) = @_;
    if ($error) {
        $self->{errors} = {} unless $self->{errors};
        $self->{errors}->{$field} = $error;
    }
    return $self->{errors};
}



sub _build_object {
    my $self = shift;
    my $field = shift;
    $self->{objects} = {} unless exists $self->{objects};

    my $params = $self->field($field); # retrieve the conf

    my $submodule = $params->{type} || "Base";
    my $options = $params->{options} || {};
    my $class = __PACKAGE__ .'::'.$submodule;
    load $class;
    my $obj = $class->new(%$options);
    $self->{objects}->{$field} = $obj; # hold it
    return $obj;
}





1;
