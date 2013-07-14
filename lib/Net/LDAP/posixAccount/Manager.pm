package Net::LDAP::posixAccount::Manager;

use 5.10.1;
use strict;
use warnings FATAL => 'all';

use Carp;
use Net::LDAP;
use Config::Simple;


=head1 NAME

Net::LDAP::posixAccount::Manager - The great new Net::LDAP::posixAccount::Manager!

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
dn - connection dn
password - connection dn password

=cut

sub new {
  my ($class, $config_file) = @_;
  $config_file = "default.cfg" if ! defined $config_file;
  croak "Config file $config_file does not exists." unless -f $config_file;
  my %conf;
  Config::Simple->import_from($config_file,\%conf);
  my $conn=Net::LDAP->new($conf{hostname});
  croak "Error in opening ldap connection.\n" if (!$conn) ;
  $conn->bind( dn=>$conf{dn},password=>$conf{password} )
	or croak "$@";
  bless {config => \%conf, connection => $conn}, $class;
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

=head2 function2

=cut

sub function2 {
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
