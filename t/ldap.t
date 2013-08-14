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
my $entry1 = Net::LDAP::Entry->new("cn=test,$manager->{config}{base}");
$entry1->add(objectClass => [ qw(top person) ] , sn => "John");
my $msg1 = $entry1->update($con);
#say $msg1->code,",",$msg1->error;
ok( $msg1->code == 0 );
ok( $msg1->error eq "Success" );

my $entry2 = Net::LDAP::Entry->new("cn=test,$manager->{config}{base}");
$entry2->changetype("modify");
$entry2->add(description => "John's description.");
my $msg2 = $entry2->update($con);
my $result2 = $con->search( base => $manager->{config}{base},
	      scope => "sub",
	      filter => "(cn=test)"
	    )->shift_entry;
ok( $result2->dn eq "cn=test,$manager->{config}{base}" );
ok( $result2->get_value("description") eq "John's description." );
ok( $msg2->code == 0 );
ok( $msg2->error eq "Success" );

my $entry3 = Net::LDAP::Entry->new("cn=test,$manager->{config}{base}");
$entry3->changetype("modify");
#modify objectClass is not allowed.
$entry3->add(objectClass => [ qw(top person organizationalPerson) ], l => "China");
my $msg3 = $entry3->update($con);
$con->search( base => $manager->{config}{base},
	      scope => "sub",
	      filter => "(cn=test)"
	    )->shift_entry;
ok( $msg3->code == 20 );

$manager->delete("(cn=test)");

done_testing();
