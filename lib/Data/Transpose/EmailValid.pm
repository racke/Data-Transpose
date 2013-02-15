package Data::Transpose::EmailValid;

use strict;
use warnings;

use Email::Valid;



sub new {
    my ($class) = @_;
    my $self = bless {}, $class;

    $self->{email_valid} = Email::Valid->new(
        -fudge   => 1,
        -mxcheck => 1,
    );

    return $self;
}

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

sub email  { (shift)->{output} }
sub reason { (shift)->{reason} }

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

1;

