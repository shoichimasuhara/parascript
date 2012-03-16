package Parascript;
use strict;
use warnings;
use Parascript::Constant;
use Parascript::Option;
use Parascript::Config;
use Parascript::Batch;
use Parascript::Interactive;

sub run{
    my $class   = shift;
    my $self    = $class->new;
    $self
        ->_get_option
        ->_get_config
        ->_exec
    ;
}

sub _get_option{
    my $self    = shift;
    $self->{_option}    = Parascript::Option->new;
    return $self;
}

sub _get_config{
    my $self    = shift;
    $self->{_option}    = Parascript::Option->new;
    return $self;
}

sub _exec{
    my $self    = shift;
    my $mode    = $self->{_option}->mode;
    if($mode eq Parascript::Constant::Batch){
        Parascript::Batch->run;
    }elsif($mode eq Parascript::Constant::Interactive){
        Parascript::Interactive->run;
    }else{
        croak('Unknown mode');
    }
}

1;
