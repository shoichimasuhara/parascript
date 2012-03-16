package Parascript::Batch;
use strict;
use warnings;
use Parascript::Executor;

sub run{
    my ($class, $c)   = @_;
    my $self    = $class->new($c);
    $self
        ->_exec
    ;
}

sub new{
    my ($class, $c)   = @_;
    my $self    = bless {
        c   => $c
    }, $class;
    return $self;
}

sub _exec{
    my $self    = shift;
    
}


1;
