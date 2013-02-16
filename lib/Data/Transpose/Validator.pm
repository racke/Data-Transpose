package Data::Transpose::Validator;

use strict;
use warnings;
use Module::Load;
use Try::Tiny;
use Data::Dumper;
use Data::Transpose::Validator::Subrefs;

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

=head2 option

Accessor to the options set

=cut

sub option {
    my ($self, $key, $value) = @_;
    $self->{options} = {} unless defined $self->{options};
    return unless $key;
    if ($key and defined $value) {
        $self->{options}->{$key} = $value;
    }
    return $self->{options}->{$key};
}

=head2 options

Accessor to get the list of the options

=cut

sub options {
    return keys %{shift->{options}}
}

=head2 prepare

C<prepare> takes a hash and pass the key/value pairs to C<field> 

=cut


sub prepare {
    my $self = shift;
    if (@_ == 1) {
        # we have an array;
        my $arrayref = shift;
        foreach my $field (@$arrayref) {
            my $fieldname = $field->{name};
            die qq{Wrong usage! When an array is passed, "name" must be set!}
              unless $fieldname;
            $self->field($fieldname, $field);
        }
    }
    else {
        my %fields = @_;
        while (my ($k, $v) = each %fields) {
            $self->field($k, $v)
        }
    }
}

=head2 field

This accessor sets the various fields and their options.

=cut

sub field {
    my ($self, $field, $args) = @_;

    # initialize
    $self->{fields} = {} unless exists $self->{fields};
    
    if ($field and $args) {
        unless ($field and (ref($field) eq '')) {
            die "Wrong usage, argument to field is mandatory\n" 
        };

        #  validate the args and store them
        if ($args and (ref($args) eq 'HASH')) {
            $self->{fields}->{$field} = $args;
        }
        # add the field to the list
        $self->_sorted_fields($field);
    }

    # behave as an accessor
    if($field) {
        return $self->{fields}->{$field}
    }
    # retrieve all
    else {
        return $self->{fields};
    }
}

# return the sorted list of fields

sub _sorted_fields {
    my ($self, $field) = @_;
    $self->{ordering} = [] unless defined $self->{ordering};
    if ($field) {
        push @{$self->{ordering}}, $field;
    }
    return @{$self->{ordering}};
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


=head2 errors

Accessor to set or retrieve the errors (returned as an arrayref of
hashes). Each element has the key C<field> set to the fieldname and
the key C<errors> holds the the error list. This, in turn, is a list
of arrays, where the first element is the error code, and the second
the human format set by the module (in English). See the method belows
for a more accessible way for the errors.

=cut

sub errors {
    my ($self, $field, $error) = @_;
    if ($error and $field) {
        $self->{errors} = [] unless $self->{errors};
        push @{$self->{errors}}, {field => $field,
                                  errors => $error};
    }
    return $self->{errors};
}

=head2 faulty_fields 

Accessor to the list of fields where the validator detected errors.

=cut

sub faulty_fields {
    my $self = shift;
    my @ffs;
    foreach my $err (@{$self->errors}) {
        push @ffs, $err->{field};
    }
    return @ffs;
}

=head2 errors_as_hashref_for_humans

Accessor to get a list of the failed checks. It returns an hashref
with the keys set to the faulty fields, and the value as an arrayref
to a list of the error messages.

=cut

sub errors_as_hashref_for_humans {
    my $self = shift;
    return $self->_get_errors_field(1);
}

=head2 errors_as_hashref

Same as above, but for machine processing. It returns the lists of
error codes as values.

=cut

sub errors_as_hashref {
    my $self = shift;
    return $self->_get_errors_field(0);
}

=head2 packed_errors($fieldsep, $separator)

As convenience, this metod will join the human readable strings using
the second argument, and introduced by the name of the field
concatenated to the first argument. Example with the defaults (colon
and comma):

  password: Wrong length, No special characters, No letters in the
  password, Found common password, Not enough different characters,
  Found common patterns: 1234
  country: My error
  email2: rfc822

It's returned as an array, so you still can process it easily.

=cut


sub packed_errors {
    my $self = shift;
    my $fieldsep = shift || ": ";
    my $separator = shift || ", ";

    my $errs = $self->errors_as_hashref_for_humans;
    my @out;
    print Dumper($errs);
    foreach my $k ($self->faulty_fields) {
        push @out, $k . $fieldsep . join($separator, @{$errs->{$k}});
    }
    return @out;
}


sub _get_errors_field {
    my $self = shift;
    my $i = shift;
    my %errors;
    foreach my $err (@{$self->errors}) {
        my $f = $err->{field};
        $errors{$f} = [] unless exists $errors{$f};
        foreach my $string (@{$err->{errors}}) {
            push @{$errors{$f}}, $string->[$i];
        }
    }
    return \%errors;
}



sub _build_object {
    my $self = shift;
    my $field = shift;
    $self->{objects} = {} unless exists $self->{objects};

    my $params = $self->field($field); # retrieve the conf

    my $validator = $params->{validator};
    my $type = ref($validator);
    my $obj;
    # if we got a string, the class is Data::Transpose::$string
    if ($type eq 'CODE') {
        $obj = Data::Transpose::Validator::Subrefs->new($validator);
    }
    else {
        my ($class, $classoptions);
        if ($type eq '') {
            my $module = $validator || "Base";
            $class = __PACKAGE__ . '::' . $module;
            # no option can be passed
            $classoptions = {};
        }
        elsif ($type eq 'HASH') {
            $class = $validator->{class};
            die "Missing class for $field\n" unless $class;
            $classoptions = $validator->{options} || {};
            # print Dumper($classoptions);
        }
        else {
            die "Wron usage. Pass a string, an hashref or a sub!\n";
        }
        # lazy loading, avoiding to load the same class twice
        try {
            $obj = $class->new(%$classoptions);
        } catch {
            load $class;
            $obj = $class->new(%$classoptions);
        };
    }
    $self->{objects}->{$field} = $obj; # hold it
    return $obj;
}





1;
