package Parascript::Constant;
use strict;
use warnings;
use Exporter::Lite;
our @EXPORT = qw(
    Batch
    Interactive
    Script
    Command
);

use constant {
    Batch       => 0,
    Interactive => 1,
    Script      => 2,
    Command     => 3
};

1;
