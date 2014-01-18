package Data::Transpose::Group;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Group - Group class for Data::Transpose

=head1 SYNOPSIS

    $group = $tp->group('fullname', $tp->field('firstname'),
                                    $tp->field('lastname'));
    
=head1 METHODS

=head2 new

    $group = Data::Transpose::Group->new(name => 'mygroup',
        objects => [$field_one, $field_two]);

=cut

sub new {
    my ($class, $self, %args);

    $class = shift;
    %args = @_;
    
    $self = {
        # name
        name => $args{name},
        # joiner
        join => ' ',
        # objects
        objects => $args{objects},        
    };

    bless $self, $class;

    return $self;
}

=head2 name

Set name of the group:

    $group->name('fullname');

Get name of the group:

    $group->name;

=cut

sub name {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{name} = $name;
        return $self;
    }

    return $self->{name};
}

=head2 fields

Returns field objects for this group:

    $group->fields;

=cut

sub fields {
    return shift->{objects};
}

=head2 join

Set string for joining field values:

    $group->join(',');

Get string for joining field values:

    $group->join;

The default string is a single blank character.

=cut
    
sub join {
    my ($self, $join) = @_;

    if (defined $join) {
        $self->{join} = $join;
        return $self;
    }

    return $self->{join};
}

=head2 value

Returns value for output:
    
    $output = $group->value;

=cut

sub value {
    my $self = shift;
    my $token;
    
    if (@_) {
        $self->{output} = shift;
    }
    else {
        # combine field values
        $self->{output} = CORE::join($self->join,
                                     map {my $value = $_->value;
                                          defined $value ? $value : '';
                                     } @{$self->{objects}});
    }
    
    return $self->{output};
}

=head2 target

Set target name for target operation:

    $group->target('name');

Get target name:

    $group->target;
    
=cut

sub target {
    my ($self, $name) = @_;

    if (defined $name) {
        $self->{target} = $name;
        return $self;
    }

    return $self->{target};
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
