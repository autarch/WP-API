package Test::XMLRPC::Lite;

use strict;
use warnings;

use parent 'XMLRPC::Lite';

our $CallTest;
our $Call;

sub call {
    shift;
    $CallTest->(@_) if $CallTest;

    return $Call;
}

1;
