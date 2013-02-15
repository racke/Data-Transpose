package Data::Transpose::PasswordPolicy;

use 5.010001;
use strict;
use warnings;
# use Data::Dumper;

our $VERSION = '0.02';

=head1 NAME

Data::Transpose::PasswordPolicy - Perl extension to enforce password policy

=head1 SYNOPSIS

  use Data::Transpose::PasswordPolicy;

  my %credentials = (username => "marco",
                    password => "My.very.very.5strong.pzwd"
                   );

  my $pv = Data::Transpose::PasswordPolicy->new(\%credentials)
  
  if (my $password = $pv->is_valid) {
    print "$password is OK";
  }
  else {
    die $pv->error
  }



=head1 DESCRIPTION

This module enforces the password policy, doing a number of checking.
The author reccomends to use passphrases instead of password, using
some special character (like punctuation) as separator, with 4-5
words in mixed case and with numbers as a good measure.

You can add the policy to the constructor, where C<minlength> is the
minimum password length, C<maxlength> is the maximum password and
C<mindiffchars> is the minimum number of different characters in the
password. Read below for C<patternlength>

By default all checkings are enabled. If you want to configure the
policy, pass an hashref assigning to the disabled checking a true
value. This will leave only the length checks in place, which you can
tweak with the accessors. For example:




  my %validate = ( username => "marco",
                   password => "ciao",
                   minlength => 10,
                   maxlength => 50,
                   patternlength => 4,
                   mindiffchars => 5,
                   disabled => {
                                 digits => 1,
                                 mixed => 1,
                               }
  my $pv = Data::Transpose::PasswordPolicy->new(\%validate)
  $pv->is_valid ? "OK" : "not OK";


See below for the list of the available checkings.

B<Please note>: the purpose of this module is not to try to crack the
password provided, but to set a policy for the passwords, which should
have some minimum standards, and could be used on web services to stop
users to set trivial password (without keeping the server busy for
seconds while we check it). Nothing more.

=cut

=head1 METHODS

=cut

=head2 new(\%credentials)

Create a new Data::Transpose::PasswordPolicy object using the
credentials provided as hashref.

=cut

sub new {
    my $class = shift;
    my $new = shift;
    my $self = {};
    if ($new and (ref($new) eq 'HASH')) {
	foreach my $par (qw/username password/) {
	    if ($new->{$par}) {
		$self->{$par} = _strip_spaces($new->{$par})
	    }
	}
	foreach my $len (qw/minlength maxlength mindiffchars patternlength/) {
	    if (my $wantedlen = $new->{$len}) {
		if ($wantedlen =~ m/0*(\d+)/) {
		    $self->{$len} = $1;
		}
	    }
	}
	# disabled
	if ($new->{disabled} and (ref($new->{disabled}) eq 'HASH')) {
	    # warn "Disabling in the constructor";
	    $self->{disabled} = $new->{disabled};
	} else {
	    # warn "Nothing disabled";
	    #	    print Dumper($new);
	    $self->{disabled} = {};
	}
    } else {
	$self = {};
    }
    bless $self, $class;
}


=head1 ACCESSORS

=head2 $obj->password($newpassword)

Set and return the new password. If no argument is provided, returns
the current. It will strip leading and trailing spaces.

=head2 $obj->username($username)

Set and return the new username. If no argument is provided, returns
the current. It will strip leading and trailing spaces.

=cut

sub password {
    my ($self, $password) = @_;
    if ($password) {
	$self->{password} = _strip_spaces($password);
    }
    if (not defined $self->{password}) {
	$self->{password} = "";
    }
    return $self->{password};
}

sub username {
    my ($self, $username) = @_;
    if ($username) {
	$self->{username} = _strip_spaces($username);
    }
    return $self->{username};
}

sub _strip_spaces {
    my $string = shift;
    return unless defined $string;
    if ($string =~ m/^\s*(.+?)\s*$/s) {
	return $1;
    } else {
	return undef;
    }
}

=head2 $obj->password_length

It returns the length of the password; 

=cut 

sub password_length {
    my $self = shift;
    return length($self->password);
}

=head2 $obj->minlength

Returns the minimum length required. If a numeric argument is
provided, set that limit. Defaults to 255;

=head2 $obj->maxlength

As above, but for the maximum. Defaults to 12;

=head2 $obj->mindiffchars

As above, but set the minimum of different characters (to avoid things like
00000000000000000ciao00000000000.

Defaults to 6;

=head2 $obj->patternlength

As above, but set the length of the common patterns we will search in
the password, like "abcd", or "1234", or "asdf". By default it's 3, so
a password which merely contains "abc" will be discarded.

This option can also be set in the constructor.

=cut

sub minlength {
    my ($self, $length) = @_;
    return $self->_get_or_set_length('minlength', $length);
}

sub maxlength {
    my ($self, $length) = @_;
    return $self->_get_or_set_length('maxlength', $length);
}

sub mindiffchars {
    my ($self, $length) = @_;
    return $self->_get_or_set_length('mindiffchars', $length);
}

sub patternlength {
    my ($self, $length) = @_;
    return $self->_get_or_set_length('patternlength', $length);
}

sub _get_or_set_length {
    my ($self, $which, $length) = @_;
    if ($length && $length =~ m/^0*(\d+)$/) {
	# set the length
	$self->{$which} = $length;
    }
    # or return the existing
    elsif (my $len = $self->{$which}) {
	return $len;
    }
    # or set the default
    else {
	if ($which eq 'maxlength') {
	    $self->{$which} = 255;
	}
	elsif ($which eq 'minlength') {
	    $self->{$which} = 12;
	}
	elsif ($which eq 'mindiffchars') {
	    $self->{$which} = 6;
	}
	elsif ($which eq 'patternlength') {
	    $self->{$which} = 3;
	}
	else {
	    die "Wrong usage! This method is internal!\n"
	}
	# warn "Setting $which to $self->{$which}";
	return $self->{$which};
    }
}

=head1 Internal algorithms

All the following methods operate on $obj->password and return the
message of the error if something if not OK, while returning false if
nothing suspicious was found.

=head2 password_length_ok

Check if the password is in the range of permitted lengths.

=cut


sub password_length_ok {
    my $self = shift;
    if (($self->password_length >= $self->minlength) and
	($self->password_length <= $self->maxlength)) {
	return undef;
    } else {
	return "Wrong length";
    }
}




my %leetperms = (
		 'a' => qr{[4a]}, 
		 'b' => qr{[8b]}, 
		 'c' => "c", 
		 'd' => "d", 
		 'e' => qr{[3e]}, 
		 'f' => "f", 
		 'g' => "g", 
		 'h' => "h", 
		 'i' => qr{[1i]}, 
		 'j' => "j", 
		 'k' => "k", 
		 'l' => qr{[l1]}, 
		 'm' => "m", 
		 'n' => "n", 
		 'o' => qr{[0o]}, 
		 'p' => "p", 
		 'q' => "q", 
		 'r' => "r", 
		 's' => qr{[5s\$]}, 
		 't' => "t", 
		 'u' => "u", 
		 'v' => "v", 
		 'w' => "w", 
		 'x' => "x", 
		 'y' => "y", 
		 'z' => "z", 
		 '0' => qr{[o0]},
		 '1' => qr{[l1]},
		 '3' => qr{[e3]},
		 '4' => qr{[4a]},
		 '5' => qr{[5s]},
		 '7' => qr{[7t]},
		 '8' => qr{[8b]},
		);

my @toppassword = ( 'password', 'link', '1234', 'work', 'god', 'job',
		   'angel', 'ilove', 'sex', 'jesus', 'connect',
		   'f*ck', 'fu*k', 'monkey', 'master', 'bitch', 'dick',
		   'micheal', 'jordan', 'dragon', 'soccer', 'killer',
		   '4321', 'pepper', 'career', 'princess' );


=head2 password_has_username

Check if the password contains the username, even if obfuscated.

Disable keyword: C<username>

=cut


# check if the password doesn't contain the username
sub password_has_username {
    my $self = shift;
    return "Missing username" unless $self->username;

    my $match = _leet_string_match($self->password, $self->username);
    if ($match) {
	return "Found username $match in password";
    } else {
	return undef
    }
}

=head2 password_has_common_password

Check if the password contains, even obfuscated, common password like
"password" et similia.

Disable keyword: C<common>

=cut


# check if the password is in the top ten :-)
sub password_has_common_password {
    my $self = shift;
    my @found;
    my $password = $self->password;
    foreach my $common (@toppassword) {
	if (_leet_string_match($password, $common)) {
	    push @found, $common;
	}
    }
    if (@found) {
	return "Found common password"
    }
    else {
	return undef;
    }
}

sub _leet_string_match {
    my ($string, $match) = @_;
    return "Missing parameter" unless ($string and $match);

    my $lcstring = lc($string); # the password
    my $lcmatch = lc($match); # the check
    my @chars = split(//, $lcmatch); # split the match

    # for each character we look up the regexp or .
    my @regexps;
    foreach my $c (@chars) {
	if (exists $leetperms{$c}) {
	    push @regexps, $leetperms{$c};
	} else {
	    push @regexps, "."; # unknown character
	}
    }
    # then we join it
    my $re = join("", @regexps);
    # and use it as re against the provided string
    #    warn "checking $lcstring against $re\n";
    if ($lcstring =~ m/$re/i) {
	# return false if the re is present in the string
	return $lcmatch
    } else {
	return undef;
    }
}



=head2 password_has_enough_different_char

Check if the password has enough different characters.

Disable keyword: C<varchars>

=cut


sub password_has_enough_different_char {
    my $self = shift;
    my %found;
    my @chars = split //, $self->password;
    my %consecutives;
    my $previous = "";
    foreach my $c (@chars) {
	$found{$c}++;
	
	# check previous char
	if ($previous eq $c) {
	    $consecutives{$c}++;    
	}
	$previous = $c;
    }
    #    print Dumper(\%found);

    # check the number of chars
    my $totalchar = scalar(keys(%found));
    if ($totalchar <= $self->mindiffchars) {
	return "Not enough different characters"
    }

    my %reportconsec;
    # check the consecutive chars;
    while (my ($k, $v) =  each %consecutives) {
	if ($v > 2) { 
	    $reportconsec{$k} = $v + 1;
	}
    }

    if (%reportconsec) {
	# we see if subtracting the number of total repetion, we are
	# still above the minimum chars.
	my $passwdlen = $self->password_length;
	foreach my $rep (values %reportconsec) {
	    $passwdlen = $passwdlen - $rep; 
	}
	if ($passwdlen < $self->minlength) {
	    return "Found too many repetitions, lowering the effectivelength: "
	      . (join(", ", (keys %reportconsec)));
	}
    }

    # given we have enough different characters, we check also there
    # are not some characters which are repeated too many times;
    # max dimension is 1/3 of the password
    my $maxrepeat = int($self->password_length / 3);
    # now get the hightest value;
    my $max = 0;
    foreach my $v (values %found) {
	$max = $v if ($v > $max);
    }
    if ($max > $maxrepeat) {
	return "Found too many repetions";
    }
    return undef;
}

=head2 password_has_mixed_chars

Check if the password has mixed cases

Disable keyword: C<mixed>

=cut


sub password_has_mixed_chars {
    my $self = shift;
    my $pass = $self->password;
    if (($pass =~ m/[a-z]/) and ($pass =~ m/[A-Z]/)) {
	return undef
    } else {
	return "No mixed case"
    }
}

=head2 password_has_specials

Check if the password has non-word characters

Disable keyword: C<specials>

=cut


sub password_has_specials {
    my $self = shift;
    if ($self->password =~ m/[\W_]/) {
	return undef
    } else {
	return "No special characters";
    }
}

=head2 password_has_digits

Check if the password has digits

Disable keyword: C<digits>

=cut


sub password_has_digits {
    my $self = shift;
    if ($self->password =~ m/\d/) {
	return undef
    } else {
	return "No digits in the password"
    }
}

=head2 password_has_letters 

Check if the password has letters

Disable keyword: C<letters>

=cut

sub password_has_letters {
    my $self = shift;
    if ($self->password =~ m/[a-zA-Z]/) {
	return undef
    } else {
	return "No letters in the password"
    }
}

=head2 password_has_patterns

Check if the password contains usual patterns like 12345, abcd, or
asdf (like in the qwerty keyboard).

Disable keyword: C<patterns>

=cut

my @patterns = (
		[ qw/1 2 3 4 5 6 7 8 9 0/ ],
		[ ("a" .. "z") ],
		[ qw/q w e r t y u i o p/ ],
		[ qw/a s d f g h j k l/ ],
		[ qw/z x c v b n m/ ]);

sub password_has_patterns {
    my $self = shift;
    my $password = lc($self->password);
    my @found;
    my $range = $self->patternlength - 1;
    foreach my $row (@patterns) {
	my @pat = @$row;
	# we search a pattern of 3 consecutive keys, maybe 4 is reasonable enough
	for (my $i = 0; $i <= ($#pat - $range); $i++) {
	    my $to = $i + $range;
	    my $substring = join("", @pat[$i..$to]);
	    if (index($password, $substring) >= 0) {
		push @found, $substring;
	    }
	}
    }
    if (@found) {
	return "Found common patterns: " . join(", ", @found);
    } else {
	return undef;
    }
}


=head1 Main methods

=head2 $obj->is_valid

Return the password if matches the policy or a false value if not.

=cut



sub is_valid {
    my $self = shift;
    unless ($self->password) {
	$self->error("Password is missing");
	return undef;
    }

    # To disable this, set the minimum to 1 and the max
    # to 255, but it makes no sense.
    $self->error($self->password_length_ok);

    unless ($self->is_disabled("specials")) {
	$self->error($self->password_has_specials);
    }

    unless ($self->is_disabled("digits")) {
	$self->error($self->password_has_digits);
    }

    unless ($self->is_disabled("letters")) {
	$self->error($self->password_has_letters);
    }

    unless ($self->is_disabled("username")) {
	$self->error($self->password_has_username);
    }

    unless ($self->is_disabled("common")) {
	$self->error($self->password_has_common_password);
    }

    unless ($self->is_disabled("varchars")) {
	$self->error($self->password_has_enough_different_char);
    }

    unless ($self->is_disabled("mixed")) {
	$self->error($self->password_has_mixed_chars);
    }

    unless ($self->is_disabled("patterns")) {
	$self->error($self->password_has_patterns)
    }
    
    if ($self->error) {
	return undef;
    } else {
	return $self->password;
    }
}


=head2 $obj->error

With argument, set the error. Without, return the errors found in the
password.

=cut


sub error {
    my ($self, $error) = @_;
    if ($error) {
	# warn "Setting $error";
	if (defined $self->{error}) {
	    $self->{error} .= $error . "; ";
	} else {
	    $self->{error} = $error . "; ";
	}
    }
    return $self->{error};
}

=head2 $obj->reset_errors

Clear the object from previous errors, in case you want to reuse it.

=cut


sub reset_errors {
    my $self = shift;
    $self->{error} = undef;
}

=head2 $obj->disable("mixed", "letters", "digits", [...])

Disable the checking(s) passed as list of strings.

=cut

sub disable {
    my $self = shift;
    $self->_enable_or_disable_check("disable", @_);
}

=head2 $obj->enable("mixed", "letters", [...])

Same as above, but enable the checking

=cut


sub enable {
    my $self = shift;
    $self->_enable_or_disable_check("enable", @_);
}

sub _enable_or_disable_check {
    my $self = shift;
    my $action = shift;
    my @args = @_;
    my $set = 0;
    die "Wrong usage! internal only!\n" unless (($action eq 'enable') or
						($action eq 'disable'));

    if (@args) {
	foreach my $what (@args) {
	    $self->_get_or_set_disable($what, $action);
	}
    }
}

=head2 $obj->is_disabled("checking")

Return true if the checking is disable.

=cut

sub is_disabled {
    my $self = shift;
    my $check = shift;
    return $self->_get_or_set_disable($check);
}

sub _get_or_set_disable {
    my ($self, $what, $action) = @_;
    return undef unless $what;
    unless ($action) {
	return $self->{disabled}->{$what}
    }
    if ($action eq 'enable') {
	$self->{disabled}->{$what} = 0;
    }
    elsif ($action eq 'disable') {
	$self->{disabled}->{$what} = 1;
    }
    else {
	die "Wrong action!\n"
    }
    return $self->{disabled}->{$what};
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
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
