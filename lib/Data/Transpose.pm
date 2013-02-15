package Data::Transpose;

use 5.010001;
use strict;
use warnings;

use Data::Transpose::Field;
use Data::Transpose::Group;

=head1 NAME

Data::Transpose - Transpose, filter and validate data

=head1 VERSION

Version 0.003

=cut

our $VERSION = '0.0003';

=head1 SYNOPSIS

    use Data::Transpose;

    my $tp = Data::Transpose->new;

=head1 METHODS

=head2 new

Parameters for the constructor are:

=over 4

=item unknown

Determines how to treat fields in the input hash
which are not known to the Data::Transpose object:

=over 4

=item fail

The transpose operation fails.

=item pass

Unknown fields in the input hash appear in the output
hash. This is the default behaviour.

=item skip

Unknown fields in the input hash don't appear in
the output hash.

=back

=back

=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    $self = {unknown => 'pass'};
    bless $self, $class;

    %args = @_;

    if (defined $args{unknown}) {
        if ($args{unknown} eq 'fail'
            || $args{unknown} eq 'pass'
            || $args{unknown} eq 'skip') {
            $self->{unknown} = $args{unknown};
        }
        else {
            die "Invalid parameter for unknown (use either fail, pass or skip).\n";
        }
    }

    $self->{fields} = [];

    return $self;
}

=head2 field

Add a new field object and returns it:

    $tp->field('email');

=cut

sub field {
    my ($self, $name) = @_;
    my ($object);

    $object = Data::Transpose::Field->new(name => $name);

    push @{$self->{fields}}, $object;

    return $object;
}

=head2 group

Add a new group object and return it:

    $tp->group('fullname', $tp->field('firstname'), $tp->field('lastname'));

=cut

sub group {
    my ($self, $name, @objects) = @_;
    
    my $object = Data::Transpose::Group->new(name => $name,
                                             objects => \@objects);

    push @{$self->{fields}}, $object;
    
    return $object;
}

=head2 transpose

=cut

sub transpose {
    my ($self, $vref) = @_;
    my ($weed_value, $fld_name, $new_name, %new_record, %status);

    $status{$_} = 1 for keys %$vref;

    for my $fld (@{$self->{fields}}) {
        $fld_name = $fld->name;

        # set value and apply operations
        if (exists $vref->{$fld_name}) {
            $weed_value = $fld->value($vref->{$fld_name});
        }
        else {
            $weed_value = $fld->value;
        }

        if ($new_name = $fld->target) {
            $new_record{$new_name} = $weed_value;
        }
        else {
            $new_record{$fld_name} = $weed_value;
        }

        delete $status{$fld_name};
    }

    if (keys %status) {
        # unknown fields
        if ($self->{unknown} eq 'pass') {
            # pass through unknown fields
            for (keys %status) {
                $new_record{$_} = $vref->{$_};
            }
        }
        elsif ($self->{unknown} eq 'fail') {
            die "Unknown fields in input: ", join(',', keys %status), '.';
        }
    }

    return \%new_record;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-transpose at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Transpose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Transpose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Transpose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Transpose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Transpose>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Transpose/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Transpose
