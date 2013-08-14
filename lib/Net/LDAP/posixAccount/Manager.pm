package Net::LDAP::posixAccount::Manager;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use utf8;

use Exporter qw(import);
use Carp;
use Net::LDAP;
use Net::LDAP::Entry;
use Config::Simple;
use List::MoreUtils qw(any);

our @EXPORT = qw( maxid new add_user delete mkgroup mkaccount );

=head1 NAME

Net::LDAP::posixAccount::Manager - The convenient class for LDAP manipulating.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::LDAP::posixAccount::Manager;

    my $foo = Net::LDAP::posixAccount::Manager->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

new( config_file )
Create a new Manager object. This Manager object has two instance fields:
1. config - the config file hash data.
2. connection - the binded ldap server connection.
config_file => configuration file name. The default config file name is "default.cfg".
The configuration file can have thest property names:
hostname - LDAP server hostname
managerdn - connection dn
password - connection dn password
max_uid_dn - the dn of the entry which is  used to savd max uidNumber
max_gid_dn - the dn of the entry which is used to save max gidNumber

=cut

sub new {
  my ($class, $config_file) = @_;
  $config_file = "default.cfg" if ! defined $config_file;
  croak "Config file $config_file does not exists." unless -f $config_file;
  my %conf;
  Config::Simple->import_from($config_file,\%conf);
  my $conn=Net::LDAP->new($conf{hostname});
  croak "Error in opening ldap connection.\n" if (!$conn) ;
  $conn->bind( $conf{managerdn},password=>$conf{password} )
	or croak "$@";
  bless {config => \%conf, connection => $conn}, $class;
}

=head2 mkaccount
mkcount(uid, name, path1, path2, ... )
Add new posix account to ldap server.
mkaccount could have many path parameters, the final dn will composed like this:
uid=$uid,ou=$path2,ou=$path1,$basedn

=cut

sub mkaccount {
  my ($self, $uid, $name) = splice @_,0,3;
  ref $self or croak "mkaccount can only be called by instance variable.";
  croak "uid or name is missing in mkaccount." if any {!defined $_} ($uid,$name);
  my @path = map "ou=$_,",reverse(@_);
  my $dn = "uid=${uid}," . join('',@path) . "$self->{config}{base}";
  my $con = $self->{connection};
  my $entry = $con->search(base=>$dn, scope=>"base", filter => "(uid=$uid)")->shift_entry;
  $entry or $entry = Net::LDAP::Entry->new( $dn );
  +{
    "entry" => sub {$entry;},
    "create" => sub {
      $entry->add(
		  cn => "$name",
		  sn => substr($name,0,1),
		  gn => substr($name,1),
		  uid => "$uid",
		  homeDirectory => "/nonexistent",
		  uidNumber => $self->maxid("uid",1),
		  gidNumber => $self->{config}{default_gid},
		  userPassword => $uid,
		  objectClass => [qw(top person organizationalPerson inetOrgPerson posixAccount)]
		 );
    },
    "update" => sub{
      $entry->update($con);
    }
   }
}

=head2 add_user

add_user( uid, name, path1, path2, ... )
Add new posix user to ldap server.
add_user could have many path parameters, the final dn will composed like this:
uid=$uid,ou=$path2,ou=$path1,$basedn

=cut

sub add_user {
  my ($self, $uid, $name) = splice @_,0,3;
  ref $self or croak "add_user can only be called by instance variable.";
  croak "uid or name is missing in add_user." if any {!defined $_} ($uid,$name);
  my @path = map "ou=$_,",reverse(@_);
  my $dn = "uid=${uid}," . join('',@path) . "$self->{config}{base}";
  my $result = $self->{connection}->add( $dn,
			    attrs => [
				cn => "$name",
				sn => substr($name,0,1),
				gn => substr($name,1),
				uid => "$uid",
				homeDirectory => "/nonexistent",
				uidNumber => $self->maxid("uid",1),
				gidNumber => $self->{config}{default_gid},
				userPassword => $uid,
				objectClass => [qw(top person organizationalPerson inetOrgPerson posixAccount)],
			   ]
	);
    $result->code && carp "Failed to add entry(add_user): " , $result->error ;

}

=head2 delete

delete(filter)
delete entry with filter in base subtree. This method is for private useage.

=cut

sub delete{
  my ($self, $filter) = @_;
  ref $self or croak "delete can only be called by instance variable.";
  defined $filter or croak "delete must have filter.";
  my $conn = $self->{connection};
  my $search = $conn->search(
			     base => $self->{config}{base},
			     scope => "sub",
			     filter => $filter,
			     callback => sub{
			       return if !defined $_[1];
			       $_[1]->delete;
			       $_[1]->update($conn);
			     }
			    );
}

=head2 mkgroup

mkgroup(name,path1,path2,...)
The composed group dn will be:
cn=$name,...,ou=$path2,ou=$path1,$basedn
mkgroup can be used to create group entry in ldap server, it can also be used to get an already existed group entry.
mkgroup returns a hash object, which can be used to manipulate group entry.

=cut

sub mkgroup{
  my ($self,$name) = splice @_,0,2;
  ref $self or croak "mkgroup can only be called by instance variable.";
  defined $name or croak "Call mkgroup must provide group name as parameter.";
  my @path = map "ou=$_,",reverse(@_);
  my $dn = "cn=$name," . join('',@path) . $self->{config}{base};
  my $con = $self->{connection};
  my $entry = $con->search(base => $dn, scope => "base", filter => "(name=$name)")->shift_entry;
  $entry or $entry = Net::LDAP::Entry->new( $dn, cn => $name );
  +{
    "entry" => sub{ $entry; },
    "class" => sub{
      my $groupclass = shift;
      $entry->changetype("add");
      given($groupclass){
	when('posixGroup') {
	  $entry->add(gidNumber => $self->maxid("gid",1));
	}
	when('groupOfNames') {
	  $entry->add(member => $self->{config}{default_group_of_names_member} );
	}
	when('groupOfUniqueNames') {
	  $entry->add(uniqueMember => $self->{config}{default_group_of_unique_names_member} );
	}
      }
      $entry->add(objectClass => [ ("top",$groupclass) ]);
    },
    "addmember" => sub{
      my @values = $entry->get_value("objectClass");
      @values == 2 or croak "Group entry($entry->dn) must have just two objectClass values.";
      my $groupclass = $values[0] eq "top" ? $values[1] : $values[0];
      $entry->changetype("modify");
      given($groupclass){
	when('posixGroup') { $entry->add(memberUid => shift); }
	when('groupOfNames') { $entry->add(member => shift); }
	when('groupOfUniqueNames') { $entry->add(uniqueMember => shift); }
      }
    },
    "update" => sub{
      $entry->update($con);
    }
   };
}

=head2 associate

associate(groupfilter,userfilter)

If thers are more than one group entry with $groupfilter, then this method will croak. This method will set user's gidNumber to this group's gidNumber, and add user's uid as group entry's memberUid.
This method will modify the groupfilter and userfilter. The real groupfilter used to search entry will be:
(&(filter from parameter)(objectClass=posixGroup))
The real userfilter used to search entry will be:
(&(filter from parameter)(objectClass=posixAccount))

=cut

sub associate{
  my ($self,$groupfilter,$userfilter) = @_;
  ref $self or croak "associate can only be called by instance variable.";
  croak "Call associate must provide groupfilter and userfilter." if any {!defined $_} ($groupfilter,$userfilter);
  $groupfilter = "(&${groupfilter}(objectClass=posixGroup))";
  $userfilter = "(&${userfilter}(objectClass=posixAccount))";
  my $conn = $self->{connection};
  my $search = $conn->search(
			     base => $self->{config}{base},
			     scope => "sub",
			     filter => $groupfilter,
			     );
  $search->count == 1 or croak "The groupfilter used by associate to search group entry must return just one entry.";
  my $group = $search->shift_entry;
  my @users = $conn->search(
			    base => $self->{config}{base},
			    scope => "sub",
			    filter => $userfilter
			    )->entries;
  foreach my $user (@users) {
    $user->replace(gidNumber=>$group->get_value("gidNumber"));
    $group->add(memberUid=>$user->get_value("uid"));
    $user->update($conn);
    $group->update($conn);
  }
}

=head2 maxid

maxid(category,increment)
When "category" is "uid", maxid will return the max uidNumber in "max_uid_dn" entry. When "category" is "gid", maxid will return the max gidNumber in "max_gid_dn" entry.
"increment" is 1 by default, means after get the max uidNumber(or gidNumber), the max uidNumber(or gidNumber) saved in ldap server will be incremented.
This function use "max_uid_dn"(or max_gid_dn) property in config file,"max_uid_dn" is the dn of entry which saved max uidNumber(or gidNumber). The objectClass attribute of this entry must include "posixAccount", and uidNumber must not be null.

=cut

sub maxid {
  my ($self, $category, $increment) = @_;
  ref $self or croak "maxid can only be called by instance variable.";
  grep /^${category}$/, qw(uid gid) or croak "category must be \"uid\" or \"gid\".";
  defined $increment or $increment = 1;
  my $dn = $self->{config}{"max_${category}_dn"};
  my $search = $self->{connection}->search(
					   base => $dn,
					   scope => "base",
					   filter => "(objectclass=*)",
					   sizelimit => 1,
					   attrs => ["${category}Number"]
					  );
  $search or croak "$dn does not exist. Check config file.";
  my $entry = $search->shift_entry;
#  $entry->dump;
  my $value = $entry->get_value("${category}Number");
  if ($increment > 0) {
    $entry->replace("${category}Number" => $value+$increment);
    $entry->update($self->{connection});
  }
  $value;
}

=head2 DESTROY

Unbind from ldap server.

=cut

sub DESTROY {
  my $self = shift;
  if(defined $self->{connection}){
    $self->{connection}->unbind;
    delete $self->{connection};
  }
}

=head1 AUTHOR

luyanfei, C<< <luyanfei78 at 163.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-posixaccount-manager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-posixAccount-Manager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::posixAccount::Manager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-posixAccount-Manager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-posixAccount-Manager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-posixAccount-Manager>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-posixAccount-Manager/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 luyanfei.

This program is released under the following license: artistic_2


=cut

1; # End of Net::LDAP::posixAccount::Manager
