#!/usr/bin/perl
use strict;

my $vm_name = $ARGV[0];
die "Usage $0 [vm-name]\n" if !$vm_name;

print "Shutting down $vm_name\n";
system("/usr/bin/VBoxManage controlvm $vm_name poweroff");

sleep 3;

print "Removing netboot from $vm_name...\n";
system("/usr/bin/VBoxManage modifyvm $vm_name --boot1 disk");
if ($? == 0) {
    print "Done.\n";
} else {
    print "Failed to remove netboot on $vm_name!\n";
    exit 1;
}

print "Starting $vm_name ..\n";
system("/usr/lib/virtualbox/VBoxHeadless -s $vm_name &");
