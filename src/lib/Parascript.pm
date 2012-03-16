package Parascript;
use strict;
use warnings;
use Parascript::Constant;
use Parascript::Container;
use Parascript::Batch;
use Parascript::Interactive;

sub run{
    my $c   = Parascript::Container->new;
    $c
        ->read_option
        ->read_config
        ->read_host_list
    ;
    if(
        $c->option->mode eq Parascript::Constant::Batch
    ){
        Parascript::Batch->run($c);


    }elsif(
        $c->option->mode eq Parascript::Constant::Interactive
    ){
        Parascript::Interactive->run($c);


    }else{
        croak('Unknown mode');
    }
}

1;
