package Parascript::ResultBucket;
use strict;
use warnings;
use IPC::SysV   qw/ IPC_CREAT IPC_EXCL IPC_RMID SETVAL ftok /;
use Storable    qw/ nfreeze thaw /;
use Time::HiRes qw/ usleep /;
use constant MAX_RETRY  => 1024;

sub new{
    my ($class, $size)  = @_;
    die("Data Size is requierd") unless $size;
    my $self    = bless {
        _size   => $size
    }, $class;
    $self->{_key}   = $self->_get_key;
    $self->{_shmid} = $self->_get_shm;
    $self->{_semid} = $self->_get_sem;
    $self->_clear;
    return $self;
}

sub add{
    my ($self, $key, $value)    = @_;
    $self->_lock;
    my $buff        = $self->_read;
    $buff->{$key}   = [] unless $buff->{$key};
    push(@{$buff->{$key}}, $value);
    $self->_write($buff);
    $self->_unlock;
}

sub set{
    my ($self, $key, $value)    = @_;
    $self->_lock;
    my $buff    = $self->_read;
    $buff->{$key}   = $value;
    $self->_write($buff);
    $self->_unlock;
}

sub dump{
    my $self    = shift;
    $self->_lock;
    my $buff    = $self->_read;
    $self->_unlock;
    return $buff;
}

sub close{
    my $self    = shift;
    $self->_destroy_sem;
    $self->_destroy_shm; 
}

sub _read{
    my $self    = shift;
    my $data;
    shmread($self->{_shmid}, $data, 0, $self->{_size}) or die;
    return thaw($data);
}

sub _write{
    my ($self, $data)   = @_;
    $data   = nfreeze($data);
    shmwrite($self->{_shmid}, $data, 0, length($data)) or die;
}

sub _lock{
    my $self    = shift;
    my $op  = pack("sss", 0, -1, 0);
    foreach (1 .. MAX_RETRY){
        semop($self->{_semid}, $op) and last;
        usleep 1;
    }
}

sub _unlock{
    my $self    = shift;
    my $op  = pack("sss", 0, 1, 0);
    foreach (1 .. MAX_RETRY){
       semop($self->{_semid}, $op) and last;
        usleep 1;
    }
}

sub _get_key{
    return ftok($0, $$);
}

sub _get_shm{
    my $self    = shift;
    return shmget(
        $self->{_key},
        $self->{_size},
        IPC_CREAT | 0644
    ) or die($!);
}

sub _get_sem{
    my $self    = shift;
    my $semid   = semget(
        $self->{_key},
        1,
        0644|&IPC_CREAT|IPC_EXCL
    );
    if(defined($semid)){
        semctl($semid, 0, &SETVAL, 1) or die($!);
    }else{
        $semid  = semget(
            $self->{_key},
            1,
            0644
        ) or die($!);
    }
    return $semid;
}

sub _clear{
    my $self    = shift;
    $self->_lock;
    $self->_write({});
    $self->_unlock;
}

sub _destroy_sem{
    my $self    = shift;
    semctl($self->{_semid}, 0, IPC_RMID, 0);
}

sub _destroy_shm{
    my $self    = shift;
    shmctl($self->{_shmid}, 0, IPC_RMID);
}

1;
