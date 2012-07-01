package Data::Transpose::Field;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Field

=head1 METHODS

=head2 new

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

=head2 transpose

=cut

sub transpose {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{transpose} = $name;
        return $self;
    }

    return $self->{transpose};
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

Copyright 2012 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
