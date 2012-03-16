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
    my ($class, $option, $config)   = @_;
    my $self    = bless {
        _option => $option,
        _config => $config
    }, $class;

    return $self;
}




1;
