# SYNOPSIS

parascript -h
parascript --help
parascript \[OPTION\] ...

    Options:
       -h --help                               display a summary of this command 
       -l --list LIST_FILE                     host list file          (You should give this script the host list
       -1 --single SINGLE_HOST                 single host              from STDIN or file or single host)
       -c --command COMMAND                    command                 (You can choice single command or script file)
       --script SCRIPT_FILE                    script file
       -i --interpreter PATH_TO_INTERPRETER    interpreter            
       --sudo                                  to execute with sudo
       -o --output PUTH_TO_OUTPUT_DIR          output directory        (Make log files like $HOST.out and $HOST.err)
       -t --test                               show command status     (Display only status OK and NG)
       --ok PATH_TO_OK_LIST_FILE               file to save OK list    (Default not saved)
       --ng PATH_TO_NG_LIST_FILE               file to save NG list    (Default not saved)
       -e --error                              show error
       -n --nohostname                         don't show hostname
       -q --quiet                              don't show at all
       -m --maxproc MAX_PROC_NUM               max proccess            (Default 20)
       -u --user USER_NAME                     ssh user name
       --ssh-key SSH_PRIVATE_KEY
       --ssh-config SSH_CONFIG,SSH_CONFIG,,,
       --ssh-known-hosts SSH_KNOWN_HOSTS_FILE
