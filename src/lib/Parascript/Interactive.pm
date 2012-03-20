package Parascript::Batch;
use strict;
use warnings;
use Parascript::Executor;

sub run{
    my ($class, $option, $config)   = @_;
    my $self    = $class->new(
        $option, $config
    );
    $self
}

sub new{
    my ($class, $c)   = @_;
    my $self    = bless {_c => $c}, $class;

    return $self;
}




1;
