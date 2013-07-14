#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::LDAP::posixAccount::Manager' ) || print "Bail out!\n";
}

diag( "Testing Net::LDAP::posixAccount::Manager $Net::LDAP::posixAccount::Manager::VERSION, Perl $], $^X" );
