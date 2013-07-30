#!perl -T
use 5.10.1;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Net::LDAP::Entry;
use Net::LDAP::posixAccount::Manager;
use Encode;

my $manager = Net::LDAP::posixAccount::Manager->new("test.conf");
my $con = $manager->{connection};

diag("Test posixGroup");
my $group = $manager->mkgroup("组的测试","groups","students","info");
$group->{class}->("posixGroup");
$group->{update}->();
my $entry1 = $con->search(base => "cn=组的测试,ou=info,ou=students,ou=groups,$manager->{config}{base}",
			  sub => "base",
			  filter => "(cn=组的测试)"
			)->shift_entry;
ok( defined $entry1, "Group entry added." );
my @objclasses = $entry1->get_value("objectClass");
is_deeply( \@objclasses, [ qw(top posixGroup) ], "Group entry's object classes are as expected." );

my $group2 = $manager->mkgroup("组的测试","groups","students","info");
$group2->{addmember}->("20130101");
$group2->{update}->();
my $entry2 = $con->search(base => "cn=组的测试,ou=info,ou=students,ou=groups,$manager->{config}{base}",
			  sub => "base",
			  filter => "(cn=组的测试)"
			)->shift_entry;
ok( $entry2->get_value("memberUid") eq "20130101", "memberUid added as expected." );

done_testing;
