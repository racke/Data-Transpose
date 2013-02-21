package Data::Transpose::Validator;

use strict;
use warnings;
use Module::Load;
use Try::Tiny;
# use Data::Dumper;
use Data::Transpose::Validator::Subrefs;

=head1 NAME

Data::Transpose::Validator - Filter and validate data.

=head1 SYNOPSIS

  use Data::Transpose::Validator;
  my $dtv = Data::Transpose::Validator->new();
  $dtv->prepare(email => {validator => 'EmailValid',
                          required => 1},
                password => {validator => 'PasswordPolicy',
                             required => 1}
               );
  
  my $form = {
              email => "aklasdfasdf",
              password => "1234"
             };
  
  my $clean = $dtv->transpose($form);
  if ($clean) {
      # the validator says it's valid, and the hashref $clean is validated
      # $clean is the validated hash
  } else {
      my $errors = $dtv->errors; # arrayref with the errors
      # old data
      my $invalid_but_filtered = $dtv->transposed_data; # hashref with the data
  }

=head1 DESCRIPTION

This module provides an interface to validate and filter hashrefs,
usually (but not necessarily) from HTML forms.

=head1 METHODS


=head2 new

The constructor. It accepts a hash as argument, with options:

C<stripwhite>: strip leading and trailing whitespace from strings (default: true)

C<requireall>: require all the fields of the schema (default: false)

C<unknown>: what to do if other fields, not present in the schema, are passed.

=over 4

C<fail>: The transposing routine will die with a message stating the unknown fields

C<pass>: The routine will accept them and return them in the validated hash 

C<skip>: The routine will ignore them and not return them in the validated hash. This is the default.

=back

C<missing>: what to do if an optional field is missing

=over 4

C<pass>: do nothing, don't add to the returning hash the missing keys. This is the default.

C<undefine>: add the key with the C<undef> value

C<empty>: set it to the empty string;

=back

=cut 


sub new {
    my ($class, %options) = @_;
    my $self = {};
    my %defaults = (
                    stripwhite => 1,
                    requireall => 0,
                    unknown => 'skip',
                    missing => 'pass',
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

=head2 option($option, [ $value ]);

Accessor to the options set. With an optional argument, set that option.

  $dtv->option("requireall"); # get 
  $dtv->option(requireall => 1); # set

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

=head2 option_for_field($option, $field)

Accessor to get the option for this particular field. First it looks
into the fields options, then into the global ones, returning the
first defined value.

  $dtv->option(email => "stripwhite");

=cut

sub option_for_field {
    my ($self, $option, $field) = @_;
    return unless ($field && $option);
    my $hash = $self->field($field);
    return unless ($hash and (ref($hash) eq 'HASH'));
    # print Dumper($hash);
    if (exists $hash->{options}) {
        if (exists $hash->{options}->{$option}) {
            # higher priority option exists, so return that
            return $hash->{options}->{$option};
        }
    }
    return $self->option($option) # return the global one;
}




=head2 options

Accessor to get the list of the options

  $dtv->options;
  # -> requireall, stripwhite, unknown

=cut

sub options {
    return sort keys %{shift->{options}}
}

=head2 prepare(%hash) or prepare([ {}, {}, ... ])

C<prepare> takes a hash and pass the key/value pairs to C<field>. This
method can accept an hash or an array reference. When an arrayref is
passed, the output of the errors will keep the provided sorting (this
is the only difference).

You can call prepare as many times you want before the transposing.
Fields are added or replaced, but you could end up with messy errors
if you provide duplicates, so please just don't do it (but feel free
to add the fields at different time I<as long you don't overwrite
them>.

  $dtv->prepare([
                  { name => "country" ,
                    required => 1,
                  },
                  {
                   name => "country2",
                   validator => 'String'},
                  {
                   name => "email",
                   validator => "EmailValid"
                  },
                 ]
                );
  
or

  $dtv->prepare(
                country => {
                            required => 1,
                           },
                country2 => {
                             validator => "String"
                            }
               );
  
  ## other code here

  $dtv->prepare(
               email => {
                         validator => "EmailValid"
                        }
               );


The validator value can be an string, a hashref or a coderef.

When a string is passed, the class which will be loaded will be
prefixed by C<Data::Transpose::Validator::> and initialized without
arguments.

If a coderef is passed as value of validator, a new object
L<Data::Transpose::Validator::Subrefs> is created, with the coderef as
validator.

If a hashref is passed as value of validator, it must contains the key
C<class> and optionally C<options> as an hashref. As with the string,
the class will be prefixed by C<Data::Transpose::Validator::>, unless
you pass the C<absolute> key set to a true value.


  $dtv->prepare(
          email => {
              validator => "EmailValid",
               },
  
          # ditto
          email2 => {
               validator => {
                       class => "EmailValid",
                      }
              },
  
          # tritto
          email3 => {
               validator => {
                       class => "Data::Transpose::Validator::EmailValid",
                       absolute => 1,
                      }
              },

          # something more elaborate
          passowrd => {
                 validator => {
                       class => PasswordPolicy,
                       options => {
                             minlength => 10,
                             maxlength => 50,
                             disabled => {
                                    username => 1,
                                   }
                            }
                      }
              }
         );
  

=cut

sub prepare {
    my $self = shift;
    if (@_ == 1) {
        # we have an array;
        my $arrayref = shift;
        die qq{Wrong usage! If you pass a single argument, must be a arrayref\n"}
          unless (ref($arrayref) eq 'ARRAY');
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

=head2 field($field)

This accessor sets the various fields and their options. It's intended
to be used only internally, but you can add individual fields with it

  $dtv->field(email => { required => 1 });

  print(Dumper($dtv->field("email"));

  print(Dumper($dtv->field);

With no arguments, it retrieves the hashref with all the fields, while
with 1 argument retrieves the hashref of that specific field.

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
    if ($field) {
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
    die "Wrong usage! A hashref as argument is needed!\n"
      unless ($hash and (ref($hash) eq 'HASH'));
    $self->reset_self;


    my (%output, %status);

    # remember which keys we had processed
    $status{$_} = 1 for keys %$hash;

    # we loop over the schema
    foreach my $field ($self->_sorted_fields) {
        my $value;
        # the incoming hash could not have such a field
        if (exists $status{$field}) {

            delete $status{$field};
            $value = $hash->{$field};

            # strip white if the option says so
            if ($self->option_for_field('stripwhite', $field)) {
                $value = $self->_strip_white($value);
            }
            # then we set it in the ouput, it could be undef;
            $output{$field} = $value;
        }
        else {
            my $missingopt = $self->option_for_field('missing', $field);
            # basically, with "pass", the default, we don't store the
            # value
            if ($missingopt eq 'undefine') {
                $value = undef;
                $output{$field} = $value;
            }
            elsif ($missingopt eq 'empty') {
                $value = "";
                $output{$field} = $value;
            }
        }
        

        # if it's required and the only thing provided is "" or undef,
        # we set an error
        if ((not defined $value) or
            ((ref($value) eq '') and $value eq '') or
            ((ref($value) eq 'HASH') and (not %$value)) or
            ((ref($value) eq 'ARRAY') and (not @$value))) {

            if ($self->field_is_required($field)) {
                # set the error list to ["required" => "Human readable" ];
                $self->errors($field,
                              [
                               [ "required" => "Missing required field $field" ]
                              ]
                             );
            }
            next;
        } 
        # we have something, validate it
        my $obj = $self->_build_object($field);
        unless ($obj->is_valid($value)) {
            my @errors = $obj->error;
            $self->errors($field, \@errors)
        }
    }
    # now the filtering loop has ended. See if we have still things in the hash.
    if (keys %status) {
        my $unknown = $self->option('unknown');
        if ($unknown eq 'pass') {
            for (keys %status) {
                $output{$_} = $hash->{$_};
            }
        } elsif ($unknown eq 'fail') {
            die "Unknown fields in input: ", join(',', keys %status), "\n";
        }
    }
    # remember what we did
    $self->transposed_data(\%output);
    # return undef if we have errors, or return the data
    return if $self->errors;
    return $self->transposed_data;
}

=head2 transposed_data

Accessor to the transposed hash. This is handy if you want to retrieve
the filtered data after a failure (because C<transpose> will return
undef in that case).

=cut


sub transposed_data {
    my ($self, $hash) = @_;
    if ($hash) {
        $self->{transposed} = $hash;
    }
    return $self->{transposed};
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

sub _reset_errors {
    my $self = shift;
    delete $self->{errors} if exists $self->{errors};
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

In scalar context it returns a string, in list context returns the
errors as an array, so you still can process it easily.

=cut


sub packed_errors {
    my $self = shift;
    my $fieldsep = shift || ": ";
    my $separator = shift || ", ";

    my $errs = $self->errors_as_hashref_for_humans;
    my @out;
    # print Dumper($errs);
    foreach my $k ($self->faulty_fields) {
        push @out, $k . $fieldsep . join($separator, @{$errs->{$k}});
    }
    return wantarray ? @out : join("\n", @out);
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

=head2 field_is_required($field)

Check if the field is required. Return true unconditionally if the
option C<requireall> is set. If not, look into the schema and return
the value provided in the schema.

=cut


sub field_is_required {
    my ($self, $field) = @_;
    return unless defined $field;
    return 1 if $self->option("requireall");
    return $self->field($field)->{required};
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
            unless ($validator->{absolute}) {
                $class = __PACKAGE__ . '::' . $class;
            }
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

sub _reset_objects {
    my $self = shift;
    delete $self->{objects} if exists $self->{objects};
}


sub _strip_white {
    my ($self, $string) = @_;
    return unless defined $string;
    return $string unless (ref($string) eq ''); # scalars only
    return "" if ($string eq ''); # return the empty string
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

=head2 reset_self

Clear all the internal data stored during validations, to make the
reusing of the transposing possible.

This is called by C<transpose> before doing any other operation

=cut

sub reset_self {
    my $self = shift;
    $self->_reset_objects;
    $self->_reset_errors;
}

1;

__END__

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://xkcd.com/936/>

=head1 AUTHOR

Marco Pessotto, E<lt>melmothx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Marco Pessotto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
