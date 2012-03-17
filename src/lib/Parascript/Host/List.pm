package Parascript::Host::List;
use strict;
use warnings;
use Parascript::Host;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw(
    hosts
));

sub new{
    my ($class, $args)  = @_;
    my $self    = bless $args, $class;
    $self->{hosts}  = [];
    return $self;
}

sub read{
    my $self    = shift;
    $self
        ->read_from_option
        ->read_from_stdin
        ->read_from_file
    ;
}

sub read_from_option{
    my $self    = shift;
    foreach my $host (@{$self->{option}->hosts}){
        push $self->{hosts}, Parascript::Host->new($host);
    }
}

sub read_from_stdin{
    my $self    = shift;
    my @list    = ();
    while(<STDIN>){
        $_  =~ s/^\s*(.*?)\s*$/$1/;
        if($_ =~ /\s/){
            $_  =~ s/\s\+/ /g;
            push @list, split(' ', $_);
        }else{
            push @list, $_;
        }
    }
    close STDIN;
    $self->{_hosts} = [@list];
}

sub read_from_file{

}

1;
