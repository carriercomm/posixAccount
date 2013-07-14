#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Net::LDAP::posixAccount::Manager;

plan tests => 1;

my $manager = Net::LDAP::posixAccount::Manager->new("test.conf");
ok( defined $manager );
