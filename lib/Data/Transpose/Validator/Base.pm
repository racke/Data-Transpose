package Data::Transpose::Validator::Base;

use strict;
use warnings;

sub new {
    my $class = shift;
    my %options = @_;
    my $self = {};
    $self->{options} = \%options;
    bless $self, $class;
}

sub is_valid {
    my ($self, $arg) = @_;
    defined $arg ? return 1 : return 0;
}

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


sub reset_errors {
    my $self = shift;
    $self->{error} = undef;
}


sub error_codes {
    my $self = shift;
    my @errors = $self->error;
    my @out;
    for (@errors) {
        push @out, $_->[0];
    }
    return @out;
}




1;
