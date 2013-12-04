#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);
use POE qw(Component::IRC  Component::IRC::Plugin::Data::SimplePassword);

my $irc = POE::Component::IRC->spawn(
    nick        => 'PassBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'PassBot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 ) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'PassBot' =>
            POE::Component::IRC::Plugin::Data::SimplePassword->new,
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}

