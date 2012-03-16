package Parascript::Results;
use strict;
use warnings;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessor(qw(
    ok_hosts ng_hosts
));

1;
