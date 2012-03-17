package Parascript::Host;
use strict;
use warnings;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw(
    name account sudo_password
));

sub new{
    my ($class, $arg)   = @_;
    my $self    = bless {}, $class;
    $self->_parse($arg);
    return $self;
}

sub _parse{
    my ($self, $arg)    = @_;
    if($arg =~ /@/){
        my ($login, $host)  = split '@', $arg;
        $self->{name}   = $host;
        if($login =~ /:/){
            my ($account, $password)    = split ':', $login;
            $self->{acccount}       = $account;
            $self->{sudo_password}  = $password;
        }else{
            $self->{account}        = $login;
        }
    }else{
        $self->{name}   = $arg;
    }
}

1;
