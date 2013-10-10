#!/usr/bin/perl

use YAML::XS qw/LoadFile/;

use strict;


my $config = LoadFile('virtual-machines.yml');

for my $vm (@{$config->{virtual_machines}}) {
    chomp(my $vm_check = `ps aux |grep -e "/usr/lib/virtualbox/VBoxHeadless -s $vm\$"|awk '{print \$2}'`);
    if ("$vm_check" ne "") {
        print "$vm is active: $vm_check\n";
    } else {
        print "Starting $vm\n";
        system("/usr/lib/virtualbox/VBoxHeadless -s $vm &");
        sleep 15;
    }
}

