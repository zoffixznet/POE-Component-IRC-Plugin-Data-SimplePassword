#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
    use_ok('POE::Component::IRC::Plugin::BasePoCoWrap');
    use_ok('POE::Component::Data::SimplePassword');
	use_ok( 'POE::Component::IRC::Plugin::Data::SimplePassword' );
}

diag( "Testing POE::Component::IRC::Plugin::Data::SimplePassword $POE::Component::IRC::Plugin::Data::SimplePassword::VERSION, Perl $], $^X" );
