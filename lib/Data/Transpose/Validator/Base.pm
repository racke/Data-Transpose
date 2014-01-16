package Data::Transpose::Validator::Base;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Validator::Base - Base class for Data::Transpose::Validator

=head1 SYNOPSIS

  my $v = Data::Transpose::Validator::Base->new;
  ok($v->is_valid("string"), "A string is valid");
  ok($v->is_valid([]), "Empty array is valid");
  ok($v->is_valid({}), "Empty hash is valid");
  ok(!$v->is_valid(undef), "undef is not valid");

=cut

=head1 METHODS (to be overwritten by the subclasses)

=head2 new()

Constructor. It accepts an hash with the options.

=cut


sub new {
    my $class = shift;
    my %options = @_;
    my $self = {};
    $self->{options} = \%options;
    bless $self, $class;
}

=head2 required

Set or retrieve the required option. Returns true if required, false
otherwise.

=cut

sub required {
    my $self = shift;
    if (@_) {
        $self->{_dtv_required} = shift;
    }
    return $self->{_dtv_required};
}

=head2 dtv_options

Set or retrieve the Data::Transpose::Validator options. Given that the
various classes have a different way to initialize the objects, this
should be done only once the object has been built.

E.g.

   my $obj = $class->new(%classoptions);
   $obj->dtv_options(\%dtv_options);

=cut

sub dtv_options {
    my $self = shift;
    if (@_) {
        $self->{_dtv_options} = shift;
    }
    return $self->{_dtv_options};
}

=head2 dtv_value

On transposing, the value of the field is stored here.

=cut

sub dtv_value {
    my $self = shift;
    if (@_) {
        $self->{_dtv_value} = shift;
    }
    defined $self->{_dtv_value} ? return $self->{_dtv_value} : return "";
}

=head2 reset_dtv_value

Delete the dtv_value from the object

=cut

sub reset_dtv_value {
    my $self = shift;
    delete $self->{_dtv_value};
}


=head2 is_valid($what)

Main method. Return true if the variable passed is defined, false if
it's undefined, storing an error.

=cut


sub is_valid {
    my ($self, $arg) = @_;
    $self->reset_errors;
    if (defined $arg) {
        return 1
    } else {
        $self->error("undefined");
        return undef;
    }
}

=head2 error

Main method to check why the validator returned false. When an
argument is provided, set the error.

In scalar context it returns a human-readable string with the errors.

In list context it returns the raw error list, where each element is a
pair of code and strings.

=cut


sub error {
    my ($self, $error) = @_;
    if ($error) {
        my $error_code_string;
        if (ref($error) eq "") {
            $error_code_string = [ $error => $error ];
        }
        elsif (ref($error) eq 'ARRAY') {
            $error_code_string = $error;
        }
        else {
            die "Wrong usage: error accepts strings or arrayrefs\n";
        }
        if (defined $self->{error}) {
	    push @{$self->{error}}, $error_code_string;
	} else {
	    $self->{error} = [ $error_code_string ];
	}
    }
    return unless defined $self->{error};
    my @errors = @{$self->{error}};

    my $errorstring = join("; ", map { $_->[1] } @errors);
    # in scalar context, we stringify
    return wantarray ? @errors : $errorstring;
}

=head2  reset_errors

Clear the errors stored.

=cut


sub reset_errors {
    my $self = shift;
    $self->{error} = undef;
}


=head2 error_codes

Returns the list of the error codes for the current validation.

=cut


sub error_codes {
    my $self = shift;
    my @errors = $self->error;
    my @out;
    for (@errors) {
        push @out, $_->[0];
    }
    return @out;
}

=head2 warnings

Set or retrieve a list of warnings issued by the validator.

=head2 reset_warnings

Reset the warning list.

=cut

sub warnings {
    my ($self, @warn) = @_;
    $self->{warnings} ||= [];
    if (@warn) {
        push @{$self->{warnings}}, @warn;
    }
    return @{ $self->{warnings} };
}

sub reset_warnings {
    my $self = shift;
    delete $self->{warnings};
}


1;
