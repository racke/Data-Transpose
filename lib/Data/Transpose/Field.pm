package Data::Transpose::Field;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Field - Field class for Data::Transpose

=head1 SYNOPSIS

     $field = $tp->field('email');

=head1 METHODS

=head2 new

    $field = Data::Transpose::Field->new(name => 'email');
    
=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    %args = @_;
    
    $self = {
        # name
        name => $args{name},
        # initial value
        raw => undef,
        # output value
        output => undef,
        # filters
        filters => [],        
    };

    bless $self, $class;

    return $self;
}

=head2 name

Set name of the field:

    $field->name('fullname');

Get name of the field:

    $field->name;

=cut

sub name {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{name} = $name;
        return $self;
    }

    return $self->{name};
}

=head2 value

Initializes field value and returns value for output:
    
    $new_value = $self->value($raw_value);

=cut

sub value {
    my $self = shift;
    my $token;
    
    if (@_) {
        $self->{raw} = shift;
        $token = $self->{raw};
        $self->{output} = $self->_apply_filters($token);
    }

    return $self->{output};
}

=head2 target

Set target name for target operation:

    $field->target('name');

Get target name:

    $field->target;

=cut

sub target {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{target} = $name;
        return $self;
    }

    return $self->{target};
}

=head2 filter

Adds a filter to the filter chain:
    
    $field->filter($code);

Returns field object.

=cut

sub filter {
    my ($self, $filter) = @_;

    if (ref($filter) eq 'CODE') {
        push @{$self->{filters}}, $filter;
    }

    return $self;
}

sub _apply_filters {
    my ($self, $token) = @_;
    
    for my $f (@{$self->{filters}}) {
        $token = $f->($token);
    }

    return $token;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
