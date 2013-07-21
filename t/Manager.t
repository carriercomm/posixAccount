#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Net::LDAP::posixAccount::Manager;

my $manager = Net::LDAP::posixAccount::Manager->new("test.conf");
ok( defined $manager, "Manager object can be created successfully.");
ok( $manager->maxid("uid"), "maxid method can be called from instance variable.");
dies_ok { Net::LDAP::posixAccount::Manager->maxid("uid") } 'maxid method cannot called from class name.';
done_testing();
