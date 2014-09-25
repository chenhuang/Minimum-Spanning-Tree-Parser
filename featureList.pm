package featureList;

sub new {
    my @args = @_;

    my $self = {};

    # if has previous list
    if ($#args == 3) {
        $self->{index} = $args[1];
        $self->{value} = $args[2];
        $self->{next}  = $args[3];
        my $feature = $self->{index};
    }

    # if there is no previous list, set up root
    if ($#args == 2) {
        $self->{index} = $args[1];
        $self->{value} = $args[2];
        my $feature = $self->{index};
    }


    bless($self, $args[0]);

    return \$self;
}

sub getIndex {
    my $self = shift;

    return $self->{index};
}

sub getValue {
    my $self = shift;

    return $self->{value};
}

sub getNext {
    my $self = shift;

    return $self->{next};
}

1;
