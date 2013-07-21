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
dies_ok { Net::LDAP::posixAccount::Manager->maxid("uid"); } 'maxid method cannot called from class name.';
dies_ok { $manager->maxid("abc"); } 'the parameter category of maxid cannot be other strings.';
my $olduid = $manager->maxid("uid",0);
my $incuid = $manager->maxid("uid",1);
ok( $olduid == $incuid, "after increment maxid returns old uid." );
my $newuid = $manager->maxid("uid",0);
ok( $newuid-$olduid == 1, "newuid($newuid) is 1 bigger than olduid($olduid)." );
my $oldgid = $manager->maxid("gid",0);
my $incgid = $manager->maxid("gid",1);
ok( $oldgid == $incgid, "after increment maxid returns old gid." );
my $newgid = $manager->maxid("gid",0);
ok( $newgid-$oldgid == 1, "newgid($newgid) is 1 bigger than oldgid($oldgid)." );
done_testing();
