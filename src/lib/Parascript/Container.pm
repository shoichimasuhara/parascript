package Parascript::Container;
use strict;
use warnings;
use Parascript::Constant;
use Parascript::Option;
use Parascript::Config;
use Parascript::Host::List;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw(
    option config host_list
));

sub read_option{
    my $self    = shift; 
    $self->{option} = Parascript::Option->new;
    return $self;
}

sub read_config{
    my $self    = shift;
    $self->{config} = Parascript::Config->new(
        $self->{config}->
    );
    return $self;
}

sub read_host_list{
    my $self    = shift;
    $self->{host_list}  = Parascirpt::Host::List->new;
    return $self;
}

1;
