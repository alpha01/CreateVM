#!/usr/bin/perl -w
use strict;

use File::Basename;
use lib dirname(__FILE__) . '/lib';
use VirtualBox::CreateVM;
use VirtualBox::AddToConfig;
use VirtualBox::AddToDHCP;

use Getopt::Long;
use Data::Dumper;

my %options;
GetOptions(\%options, "name|n:s", "disk|d:i",  "memory|m:i", "ostype|o:s", "help");

if ($options{help}) {
    usage();

} elsif ($options{name} && $options{disk} && $options{memory}) {
    my $new_vm = VirtualBox::CreateVM->new(name => $options{name}, disk => $options{disk}, memory => $options{memory}, ostype => $options{ostype});
    $new_vm->virtual_machines_location('/home/tony/VirtualBox VMs');
    $new_vm->create_vm;
    #print Dumper($new_vm);

    my $push_to_dhcp = VirtualBox::AddToDHCP->new(name => $new_vm->{name}, hardware => $new_vm->{hardware}, dhcp => '192.168.1.2');
    $push_to_dhcp->add_to_dhcp('-oConnectTimeout=5 -p 1088');
    #print Dumper($push_to_dhcp);

    VirtualBox::AddToConfig::config(name => $new_vm->{name});

} else {
    usage();
}



sub usage {
print <<EOF;

$0: Creates a new VirtualBox Virtual Machine.

Syntax: $0 [--help|--name=<VM-name> --disk=<size-in-MB> --memory=<size-in-MB>]

   --help   | -h  : This help message
   --name   | -n  : Name of the new virtual machine instance.
   --disk   | -d  : Disk Size in MB.
   --memory | -m  : Memory in MB.

Optionally,
   --ostype | -o  : Operating System type.

EOF
exit 1;
}
