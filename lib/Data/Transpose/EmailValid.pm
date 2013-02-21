package Data::Transpose::EmailValid;

use strict;
use warnings;

use base 'Data::Transpose::Validator::Base';

use Email::Valid;


=head1 NAME

Data::Transpose::EmailValid - Perl extension to check if a mail is valid (with some autocorrection)

=head1 SYNOPSIS

  use Data::Transpose::EmailValid;

  my $email = Data::Transpose::EmailValid->new;

  ok($email->is_valid("user@domain.tld"), "Mail is valid");

  ok(!$email->is_valid("user_e;@domain.tld"), "Mail is not valid");

  warn $email->reason; # output the reason of the failure

=head1 DESCRIPTION

This module check if the mail is valid, using the L<Email::Valid>
module. It also provides some additional methods.

=head1 METHODS

=head2 new

Constructor. It doesn't accept any arguments.

=cut

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;

    $self->{email_valid} = Email::Valid->new(
        -fudge   => 1,
        -mxcheck => 1,
    );

    return $self;
}

# accessor read only to the Email::Valid object

=head2 email_valid

Accessor to the Email::Valid object

=cut

sub email_valid {
    my $self = shift;
    return $self->{email_valid};
}

=head2 input

Accessor to the input email string.

=cut 

sub input {
    my ($self, $input) = @_;
    if (defined $input) {
        $self->{input} = $input;
    }
    return $self->{input};
}

=head2 output

Accessor to the output email string.

=cut

sub output {
    my ($self, $output) = @_;
    if (defined $output) {
        $self->{output} = $output;
    }
    return $self->{output};


}

=head2 reset_all 

Clear all the internal data

=cut


sub reset_all {
    my $self = shift;
    $self->reset_errors;
    foreach (qw/input output/) {
        delete $self->{$_} if exists $self->{$_}
    }
}





=head2 $obj->is_valid($emailstring);

Returns the email passed if valid, false underwise.

=cut


sub is_valid {
    return if @_ == 1;

    my ($self, $email) = @_;

    # overwrite old data
    $self->reset_all;

    $self->input($email);

    # correct common typos # Maybe add an option for this?
    $email = $self->_autocorrect;

    # do validation
    $email = $self->email_valid->address($email);
    unless ($email) {
        $self->error($self->email_valid->details);
        return;
    }

    # check for bad characters
    if ($email =~ /'/) {
        $self->error('bad_chars');
        return;
    }

    $self->output($email);
    return $email;
}

=head2 $obj->email

Returns the last checked email.

=cut

sub email  { shift->output }

=head2 $obj->reason

Returns the reason of the failure of the last check, false if it was
successful.

=cut


sub reason { shift->error }

=head2 $obj->suggestion

This module implements some basic autocorrection. Calling ->suggestion
after a successfull test, will return the suggested value if the input
was different from the output, false otherwise.

=cut

sub suggestion {
    my ($self) = @_;
    return if $self->error;

    if ($self->input ne $self->output) {
        return $self->output;
    }

    return;
}


sub _autocorrect {
    my $self = shift;
    my $email = $self->input;
    # trim
    $email =~ s/^\s+//;
    $email =~ s/\s+$//;
    # .ocm -> .com
    foreach (qw/aol gmail hotmail yahoo/) {
        $email =~ s/\b$_\.ocm$/$_.com/;
    }
    # setting the error breaks the retrocompatibility
    # $self->error("typo?");
    return $email;
}

=head1 AUTHOR

Uwe Voelker <uwe@uwevoelker.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Uwe Voelker <uwe@uwevoelker.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


1;

