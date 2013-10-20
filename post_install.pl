#!/usr/bin/perl

# Running this after Kickstart/Debian netboot install.

use strict;

my $vm_name = $ARGV[0];
die "Usage $0 [vm-name]\n" if !$vm_name;

chomp(my $vboxmanage_bin = `which VBoxManage`);
chomp(my $vboxheadless_bin = `which VBoxHeadless`);


print "Shutting down $vm_name\n";
system("$vboxmanage_bin controlvm $vm_name poweroff");

sleep 3;

print "Removing netboot from $vm_name...\n";
system("$vboxmanage_bin modifyvm $vm_name --boot1 disk");
if ($? == 0) {
    print "Done.\n";
} else {
    print "Failed to remove netboot on $vm_name!\n";
    exit 1;
}

print "Starting $vm_name ..\n";
system("$vboxheadless_bin -s $vm_name &");
