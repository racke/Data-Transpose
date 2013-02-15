package Data::Transpose::EmailValid;

use strict;
use warnings;

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

=head2 $obj->is_valid($emailstring);

Returns the email passed if valid, false underwise.

=cut


sub is_valid {
    return if @_ == 1;

    my ($self, $email) = @_;

    # overwrite old data
    $self->{input} = $email;
    delete $self->{output};
    delete $self->{reason};

    # correct common typos
    $email = $self->_autocorrect($email);

    # do validation
    $email = $self->{email_valid}->address($email);
    unless ($email) {
        $self->{reason} = $self->{email_valid}->details;
        return;
    }

    # check for bad characters
    if ($email =~ /'/) {
        $self->{reason} = 'bad_chars';
        return;
    }

    $self->{output} = $email;

    return $email;
}

=head2 $obj->email

Returns the last checked email.

=cut

sub email  { (shift)->{output} }

=head2 $obj->reason

Returns the reason of the failure of the last check, false if it was
successful.

=cut


sub reason { (shift)->{reason} }

=head2 $obj->suggestion

This module implements some basic autocorrection. Calling ->suggestion
after a successfull test, will return the suggested value if the input
was different from the output, false otherwise.

=cut

sub suggestion {
    my ($self) = @_;
    return if $self->{reason};

    if ($self->{input} ne $self->{output}) {
        return $self->{output};
    }

    return;
}


sub _autocorrect {
    my ($self, $email) = @_;

    # trim
    $email =~ s/^\s+//;
    $email =~ s/\s+$//;

    # .ocm -> .com
    foreach (qw/aol gmail hotmail yahoo/) {
        $email =~ s/\b$_\.ocm$/$_.com/;
    }

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

