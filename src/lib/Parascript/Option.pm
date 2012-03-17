package Parascript::Option;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Parascript::Constant;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_ro_accessors(qw(
    help mode hosts command script script_file_path output_dir
    stdout stderr maxproc ok ok_list_file_path ng_list_file_path sudo
));

sub new{
    my $class   = shift;
    my $self    = bless {}, $class;
    $self->_get_options;
    return $self;
}

sub _get_options{
    my $self    = shift;
    my ($help, $interactive);
    GetOptions(
        "h|help"            => \$self->{help},
        "hosts=s"           => \$self->{hosts},
        "c|command=s"       => \$self->{command},
        "s|script=s"        => \$self->{script_file_path},
        "i|interactive"     => \$interactive,
        "interpreter=s"     => \$self->{interpreter},
        "sudo"              => \$self->{sudo},
        "ok=s"              => \$self->{ok_file_path},
        "ng=s"              => \$self->{ng_file_path},
        "o|stdout"          => \$self->{stdout},
        "e|stderr"          => \$self->{stderr},
        "d|dir"             => \$self->{output_dir},
        "m|maxproc=i"       => \$self->{maxproc},
        "timeout=i"         => \$self->{timeout},
#        "n|nohostname"      => \$self->{no_hostname},
#        "ssh-key=s"         => \$self->{_ssh_key},
#        "ssh-config=s"      => \$self->{_ssh_config},
#        "ssh-known-hosts=s" => \$self->{_ssh_known_hosts},
    ) or pod2usage(2);
    $self->{mode}   = $interactive ? 
        Parascript::Constant::Interactive : Parascript::Constant::Batch
    ;
    return $self;
}

1;
