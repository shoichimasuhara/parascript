package Parascript::Executor;
use strict;
use warnings;
use Parallel::ForkManager;
use Parascript::Executor::SSHBatch;

sub _exec{
    my $self    = shift;
    my $pm  = Parallel::ForkManager->new(
        
    );

    foreach my $host    = 




}


1;
