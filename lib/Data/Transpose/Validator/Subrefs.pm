package Data::Transpose::Validator::Subrefs;
use strict;
use warnings;

use base 'Data::Transpose::Validator::Base';

sub new {
    my $class = shift;
    my $new = shift;
    die "You have to pass a subref to this class!\n"
      unless (ref($new) eq 'CODE');
    my $self = {
                call => $new,
               };
    bless $self, $class;
}

sub call {
    return shift->{call};
}


sub is_valid {
    my ($self, $arg) = @_;
    my ($result, $error) = $self->call->($arg);
    if ($error) {
        $self->error($error);
        return undef;
    } else {
        return $result;
    }
}


1; # the last famous words

