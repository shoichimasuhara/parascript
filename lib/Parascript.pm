package Parascript;
use strict;
use warnings;

our $VERSION    = '0.3.0';

use Getopt::Long;
use Pod::Usage;
use MIME::Base64;
use Parallel::ForkManager;
use Symbol;
use Net::SSH qw/ sshopen3 /;
use Term::ANSIColor qw/ colored /;
use Path::Class qw/ dir file /;
use Data::Dumper;

$Term::ANSIColor::AUTORESET = 1;

sub run{
    my $self    = __PACKAGE__->_new;
    $self
        ->_init ->_exec
    ;
}

sub _new{
    my $class   = shift;
    my $self    = bless {
        _maxproc            => 20,
        _results            => {SUCC  => [], FAIL => []},
        _list_stdin         => -p STDIN ? 1 : undef,
        _list_file          => undef,
        _user               => $ENV{USER}, 
        _hosts              => undef,
        _single_host        => undef,
        _sudo               => undef,
        _sudo_passwd        => undef,
        _command            => undef,
        _script_file        => undef,
        _interpreter        => undef,
        _output_dir         => undef,
        _show_status        => 1,
        _succ_list_file     => undef,
        _fail_list_file     => undef,
        _no_hostname        => undef,
        _show_out           => undef,
        _show_err           => undef,
        _host               => undef,
        _status             => undef,
        _out                => '',
        _err                => '',
        _quiet              => undef,
        _timeout            => 10,
        _ssh_key            => undef,
        _ssh_config         => '/etc/ssh/ssh_config,~/.ssh/config',
        _ssh_known_hosts    => undef
    }, $class;
    return $self;
}

sub _init{
    my $self    = shift;
    $self
        ->_get_options
        ->_check_options
        ->_read_list
        ->_get_sudo_passwd
        ->_create_command_line
    ;
    return $self;
}

sub _get_options{
    my $self    = shift;
    GetOptions(
        "v|version"         => \$self->{_version},
        "h|help"            => \$self->{_help},
        "l|list=s"          => \$self->{_list_file},
        "1|single=s"        => \$self->{_single_host},
        "c|command=s"       => \$self->{_command},
        "s|script=s"        => \$self->{_script_file},
        "i|interpreter=s"   => \$self->{_interpreter},
        "nostatus"          => \$self->{_no_status},
        "sudo"              => \$self->{_sudo},
        "log=s"             => \$self->{_output_dir},
        "succ=s"            => \$self->{_succ_list_file},
        "fail=s"            => \$self->{_fail_list_file},
        "o|stdout"          => \$self->{_show_out},
        "e|stderr"          => \$self->{_show_err},
        "n|nohostname"      => \$self->{_no_hostname},
        "q|quiet"           => \$self->{_quiet},
        "m|maxproc=i"       => \$self->{_maxproc},
        "u|user=s"          => \$self->{_user},
        "timeout=i"         => \$self->{_timeout},
        "ssh-key=s"         => \$self->{_ssh_key},
        "ssh-config=s"      => \$self->{_ssh_config},
        "ssh-known-hosts=s" => \$self->{_ssh_known_hosts},
    ) or pod2usage(2);
    $self->{_show_status}   = undef if $self->{_no_status};
    return $self;
}

sub _check_options{
    my $self    = shift;

    pod2usage if $self->{_help};
    $self->_show_version if $self->{_version};

    $self->_file_check($_) foreach qw/ list script /;
    $self->_dir_check($_) foreach qw/ output /;

    if(
        $self->{_script_file}   and
        ! $self->{_interpreter}
    ){
        unless($self->_get_interpreter){
            print "\nYou should set the path of the interpreter\n\n";
            pod2usage;
        }
    }

    pod2usage unless
        ($self->{_list_stdin} or $self->{_list_file} or $self->{_single_host})      and
        ($self->{_command} or ($self->{_script_file} and $self->{_interpreter}))
    ;

    return $self;
}

sub _show_version {
    my $self    = shift;
    print "Version: $VERSION\n";
    exit;
}

sub _file_check{
    my ($self, $type)   = @_;
    my $key         = '_' . $type . '_file';
    die $type . ' file "' . $self->{$key} . '" is not a file'
                            if $self->{$key} && ! -f $self->{$key};
}

sub _dir_check{
    my ($self, $type)   = @_;
    my $key         = '_' . $type . '_dir';
    die $type . ' directory "' . $self->{$key} . '" is not directory'
                            if $self->{$key} && ! -d $self->{$key};
}

sub _get_interpreter{
    my $self    = shift;
    open my $script, '<', $self->{_script_file};
    my $shebang = <$script>;
    close $script;
    if($shebang =~ /^#!/){
        $shebang    =~ s/^#!//g;
        chomp $shebang;
        $self->{_interpreter}   = $shebang;
        return 1;
    }else{
        return 0;
    }
}

sub _read_list{
    my $self    = shift;
    $self->_read_list_from_file                 if $self->{_list_file};
    $self->_read_list_from_stdin                if $self->{_list_stdin};
    $self->{_hosts} = [$self->{_single_host}]   if $self->{_single_host};
    return $self;
}

sub _read_list_from_stdin{
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

sub _read_list_from_file{
    my $self    = shift;
    my @list    = ();
    open my $in, '<', $self->{_list_file};
    while(<$in>){
        chomp $_;
        push @list, $_;
    }
    close $in;
    $self->{_hosts} = [@list];
}

sub _get_sudo_passwd{
    my $self    = shift;

    if($self->{_sudo}){
        $|  = 1;
        print STDERR "Please input your password for sudo > ";
        $|  = 0;
        open TTY, '<', '/dev/tty';
        system 'stty -echo';
        chomp(my $passwd    = <TTY>);
        system 'stty echo';
        close TTY;
        print "\n";
        $self->{_sudo_passwd}   = $passwd;
    }
    return $self;
}

sub _create_command_line{
    my $self    = shift;

    my $base64_commands;
    if($self->{_script_file}){
        $base64_commands    = encode_base64($self->_read_script);
    }else{
        $base64_commands    = encode_base64($self->{_command});
    }

    $self->{_interpreter}   = 'bash' unless $self->{_interpreter};
    $self->{_command}       =
            'echo "' . $base64_commands .
            '"|base64 -d -i|' .
            $self->{_interpreter}
    ;
    $self->{_command}   = "bash -c '" . $self->{_command} . "'";
    $self->{_command}   = 'sudo -S ' . $self->{_command} if $self->{_sudo};
    return $self;
}

sub _read_script{
    my $self    = shift;
    open my $in, '<', $self->{_script_file};
    read $in, my $script, -s $self->{_script_file};
    close $in;
    return $script;
}

sub _exec{
    my $self    = shift;


    my $pm      = Parallel::ForkManager->new($self->{_maxproc});
    $pm->run_on_finish(sub{$self->_run_on_finish(@_);});
    $|=0;
    foreach my $host (@{$self->{_hosts}}){
        $pm->start and next;

        $self->{_host}  = $host;

        my $buff    = '';
        $buff       .= $self->_make_header;
        $self->_exec_ssh;
        $buff       .= $self->_make_contents;
        $self->_logging;

        unless($self->{_quiet}){
            $|=1;
            print $buff;
            $|=0;
        }
        $pm->finish($self->{_status}, \$self->{_host});
    }
    $pm->wait_all_children;
    $self->_display_fail_hosts;
}
sub _run_on_finish{
    my $self    = shift;
    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
    if($exit_code){
        push @{$self->{_results}->{SUCC}}, $$data;
    }else{
        push @{$self->{_results}->{FAIL}}, $$data;
    }
}

sub _exec_ssh{
    my $self    = shift;

    $self->_init_ssh;

    my ($in, $out, $err)    = (gensym, gensym, gensym);
    my $pid = sshopen3(
        $self->{_user}.'@'.$self->{_host},
        $in, $out, $err,
        $self->{_command}
    );

    print $in $self->{_sudo_passwd} . "\n" if $self->{_sudo};
    close $in;

    while(<$out>){
        chomp $_; 
        $self->{_out}   .= $_ . "\n";
    }
    close $out;

    while(<$err>){
        chomp $_;
        $self->{_err}   .= $_ . "\n";
    }
    close $err; 

    waitpid $pid, 0;
    $self->{_status}    = $?>>8 ? 0 : 1; 
}

sub _init_ssh{
    my $self    = shift;
    my @ssh_options = ();
    foreach my $ssh_config (split(',', $self->{_ssh_config})){
        $ssh_config = $self->_expand_tilde($ssh_config);
        push @ssh_options, ('-F', $ssh_config)  if -f $ssh_config;
    }
    if($self->{_ssh_key}){
        my $ssh_key = $self->_expand_tilde($self->{_ssh_key});
        push @ssh_options, ('-i', $ssh_key)     if -f $ssh_key;
    }
    if($self->{_ssh_known_hosts}){
        my $ssh_known_hosts = $self->_expand_tilde($self->{_ssh_known_hosts});
        push @ssh_options, ('-o', 'UserKnownHostsFile=' . $ssh_known_hosts);
    }
    push @ssh_options, (
        '-T',
        '-o', 'BatchMode=yes',
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'ConnectTimeout=' . $self->{_timeout}
    );
    @Net::SSH::ssh_options  = @ssh_options;
}

sub  _expand_tilde{
    my ($self, $path)   = @_;
    $path =~ s{
      ^ ~             # find a leading tilde
      (               # save this in $1
          [^/]        # a non-slash character
                *     # repeated 0 or more times (0 means me)
      )
    }{
      $1
          ? (getpwnam($1))[7]
          : ( $ENV{HOME} || $ENV{LOGDIR} )
    }ex;
    return $path;
}

sub _make_header{
    my $self    = shift;
    my $buff    = '';
    $buff       = colored('### ' . $self->{_host} . " ##############################\n", 'BLUE')
        if ($self->{_show_out} or $self->{_show_err}) and !$self->{_no_hostname};
    return $buff;
}

sub _make_contents{
    my $self    = shift;
    my $buff    = '';
    if($self->{_show_status}){ 
        $buff   .= $self->{_host} . "\t";
        if($self->{_status}){
            $buff   .= colored("SUCC\n", "YELLOW");
        }else{
            $buff   .= colored("FAIL\n", "RED");
        }
    }
    if($self->{_show_out}){
        $buff   .= colored("==STDOUT====\n", 'YELLOW') if $self->{_show_err};
        $buff   .= $self->{_out};
        $buff   .= "\n" unless $self->{_no_hostname};
    }
    if($self->{_show_err}){
        $buff   .= colored("==STDERR====\n", 'RED');
        $buff   .= $self->{_err};
        $buff   .= "\n" unless $self->{_no_hostname};
    }
    return $buff;
}

sub _logging{
    my $self    = shift;
    if($self->{_output_dir} and -d $self->{_output_dir}){
        foreach my $type (qw/ out err /){
            my $io  = dir($self->{_output_dir})->file($self->{_host} . '.' . $type)->open('a');
            $io->print($self->{'_' . $type});
            $io->close;
        }
    }
    foreach my $type (qw/ succ fail /){
        my $file    = '_' . $type . '_list_file';
        if(
            $self->{$file} and
            (
                ($self->{_status} and $type eq 'succ') or
                (!$self->{_status} and $type eq 'fail')
            )
        ){
            my $io  = file($self->{$file})->open('a');
            $io->blocking(1);
            $io->print($self->{_host} . "\n");
            $io->close;
        }
    }
}

sub _display_fail_hosts{
    my $self        = shift;
    my $fail_hosts  = $self->{_results}->{FAIL};
    if($fail_hosts and ref $fail_hosts eq 'ARRAY' and scalar(@{$fail_hosts})){
        my $buff    = '';
        $buff       .= colored("==FAIL HOSTS====\n", 'RED');
        $buff       .= join("\n", @{$fail_hosts});
        $buff       .= "\n";
        print STDERR $buff;
    }
}

1;
