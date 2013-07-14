use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Net::LDAP::posixAccount::Manager',
    license             => 'artistic_2',
    dist_author         => q{luyanfei <luyanfei78@163.com>},
    dist_version_from   => 'lib/Net/LDAP/posixAccount/Manager.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Net::LDAP'              => 0.56,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Net-LDAP-posixAccount-Manager-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
