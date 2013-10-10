#!/usr/bin/perl
use strict;

# running this after kickstart install

my $vm_name = $ARGV[0];
die "Usage $0 [vm-name]\n" if !$vm_name;

print "Shutting down $vm_name\n";
system("/usr/bin/VBoxManage controlvm $vm_name poweroff");

sleep 5;

print "Removing $vm_name netboot\n";
system("/usr/bin/VBoxManage modifyvm $vm_name --boot1 disk");
