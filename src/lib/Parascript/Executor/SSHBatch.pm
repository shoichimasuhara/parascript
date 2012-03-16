package Parascript::Executor::SSHBatch;
use strict;
use warnings;
use Carp qw( croak );
use Net::SSH qw( sshopen3 );
use Symbol;
use MIME::Base64;

use Exporter::Lite;
our @EXPORT = qw( Script Command );
use constant {
    Script  => 0,
    Command => 1
};

use Class::Accessor::Lite (
    sudo_password	=> undef,
    command	        => undef,
    script	        => undef,
    host	        => undef,
    interpreter     => undef,
    timeout	        => undef,
    account	        => undef,
    stdout	        => undef,
    stderr	        => undef,
);

sub prepare{
    my ($self, $type)   = @_;
    my $code;
    if($type eq Script){
        croak('Set a script file path') unless $self->{script};
        $code   = $self->_read_script;
        $self->{interpreter}    = $self->_get_interpreter($code);
    }elsif($type eq Command){
        croak('Set a command') unless $self->{command};
        $code   = $self->{command};
        $self->{interpreter}    ||= 'bash';
    }else{
        croak('Unknown type');
    }
    my $encoded_command = encode_base64($code);
    chomp $encoded_command;

    return $self->{_concrete_command_line} = $self->_create_command_line($encoded_command);
}
sub _read_script{
    my $self    = shift;
    open my $in, '<', $self->{script};
    read $in, my $script, -s $self->{script};
    close $in;
    return $script;
}

sub _get_interpreter{
    my ($self, $code)   = @_;
    my $first_line  = ((split "\n", $code)[0]);
    unless($first_line  =~ /^#!/){
        croak('Shebang not found');
    }
    $first_line =~ s/^#!//g;
    chomp $first_line;

    return $first_line;
}

sub _create_command_line{
    my ($self, $encoded_code)   = @_;
    my $command_line    = 'echo "' . $encoded_code . '"|base64 -d -i|' . $self->{interpreter};
    $command_line       = "bash -c '" . $command_line . "'";
    $command_line       = 'sudo -S ' . $command_line if $self->{sudo_password};

    return $command_line;
}

sub exec{
    my ($self, $host) = @_;

    @Net::SSH::ssh_options  = (
        '-T',
        '-o', 'BatchMode=yes',
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'ConnectTimeout=10'
    );

    my $account =   $self->{account};
    $account    ||= getpwuid($>);
    my ($in, $out, $err)    = (gensym, gensym, gensym);
    my $pid = sshopen3(
        $account . '@' . $host,
        $in, $out, $err,
        $self->{_concrete_command_line}
    );

    print $in $self->{sudo_passwd} . "\n" if $self->{sudo}; close $in;
    $self->{stdout}  = $self->_arrange_output($out);     close $out;
    $self->{stderr}  = $self->_arrange_output($err);     close $err;

    waitpid $pid, 0;
    $self->{_status}     = $?>>8 ? 0 : 1;
}

sub _arrange_output{
    my ($self, $output) = @_;
    my $buff    = '';
    while(<$output>){
        chomp $_;
        $buff   .= $_ . "\n";
    }
    $buff;
}

1;
