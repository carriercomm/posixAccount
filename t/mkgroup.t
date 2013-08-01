#!perl -T
use 5.10.1;
use strict;
use utf8;
use warnings FATAL => 'all';
use List::MoreUtils qw(any);
use Test::More;
use Test::Exception;
use Net::LDAP::Entry;
use Net::LDAP::posixAccount::Manager;
use Encode;

my $manager = Net::LDAP::posixAccount::Manager->new("test.conf");
my $con = $manager->{connection};

diag("Test posixGroup");
$manager->delete("(cn=组的测试)");
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

$manager->delete("(cn=组的测试)");
my $groupsearch = $con->search(
			 base => $manager->{config}{base},
			 scope => "sub",
			 filter => "(cn=组的测试)",
			 sizelimit => 1
			 );
ok( $groupsearch->count == 0 );

diag("Test groupOfNames");
$manager->delete("(cn=groupOfNames组)");
my $group3 = $manager->mkgroup("groupOfNames组","groups","students","info");
$group3->{class}->("groupOfNames");
$group3->{update}->();
my $entry3 = $con->search(base => "cn=groupOfNames组,ou=info,ou=students,ou=groups,$manager->{config}{base}",
			  sub => "base",
			  filter => "(cn=groupOfNames组)"
			 )->shift_entry;
ok( defined $entry3, "groupOfNames entry added." );
my @objclasses2 = $entry3->get_value("objectClass");
is_deeply( \@objclasses2, [ qw(top groupOfNames) ], "It's groupOfNames entry.");

my $group4 = $manager->mkgroup("groupOfNames组","groups","students","info");
$group4->{addmember}->("uid=201301010001,ou=students,ou=people,$manager->{config}{base}");
$group4->{update}->();
my $entry4 = $con->search(base => "cn=groupOfNames组,ou=info,ou=students,ou=groups,$manager->{config}{base}",
			  sub => "base",
			  filter => "(cn=groupOfNames组)"
			 )->shift_entry;
#say $entry4->get_value("member");
ok( any { $_ eq "uid=201301010001,ou=students,ou=people,$manager->{config}{base}"} $entry4->get_value("member"));
$manager->delete("(cn=groupOfNames组)");
done_testing;
