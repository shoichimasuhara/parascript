package Parascript::Executor;
use strict;
use warnings;
use Parallel::ForkManager;
use Parascript::Executor::SSHBatch;
use Class::Accessor:Lite;
Class::Accessor::Lite->mk_accessors(
    c => undef
);

sub exec{
    my $self    = shift;
    my $pm  = Parallel::ForkManager->new($self->c->{option}->max_proc);

    my $ssh = Parascript::Executer::SSHBatch->new;

    foreach my $host (@{$hosts}){
        $pm->start and next;
        $ssh->exec({
            host    => $host,
            sudo    => $sudo,
        });
        $pm->finish;
    }
    $pm->wait_all_children;


}


1;
