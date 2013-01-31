use inc::Module::Install;

all_from 'lib/Parascript.pm';

requires 'Data::Dumper';
requires 'Getopt::Long';
requires 'IPC::SysV';
requires 'MIME::Base64';
requires 'Net::SSH';
requires 'Parallel::ForkManager';
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Term::ANSIColor';
requires 'Time::HiRes';
requires 'Storable';
requires 'Symbol';

build_requires 'App::FatPacker';
test_requires 'Test::More';

WriteAll;
