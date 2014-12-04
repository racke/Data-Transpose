package Data::Transpose;

use 5.010001;
use strict;
use warnings;

use Data::Transpose::Field;
use Data::Transpose::Group;

=head1 NAME

Data::Transpose - Transpose, iterate, filter and validate data

Caters to your needs for manipulating data by different operations,
which are filtering records, iterating records, validating and
transposing to different field names.

=head1 VERSION

Version 0.0011

=cut

our $VERSION = '0.0011';

=head1 SYNOPSIS

    use Data::Transpose;

    my $tp = Data::Transpose->new;

=head1 REFERENCE

=over 4

=item Validator

L<Data::Transpose::Validator>

=item Iterator

L<Data::Transpose::Iterator>

=back

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

This doesn't apply to the L</transpose_object> method.

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

Add a new L<field|Data::Transpose::Field> object and return it:

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

Add a new L<group|Data::Transpose::Group> object and return it:

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

Transposes input:

   $new_record = $tp->transpose($orig_record);

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

=head2 transpose_object

Transposes an object into a hash reference.

=cut

sub transpose_object {
    my ($self, $obj) = @_;
    my ($weed_value, $fld_name, $new_name, %new_record, %status);

    for my $fld (@{$self->{fields}}) {
        $fld_name = $fld->name;

        # set value and apply operations
        if ($obj->can($fld_name)) {
            $weed_value = $fld->value($obj->$fld_name());
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
    }

    return \%new_record;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests at
L<https://github.com/racke/Data-Transpose/issues>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Transpose

You can also look for information at:

=over 4

=item * Github's issue tracker (report bugs here)

L<https://github.com/racke/Data-Transpose/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Transpose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Transpose>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Transpose/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2014 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Transpose
