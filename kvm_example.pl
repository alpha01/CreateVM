#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib';
use KVM::CreateVM;

use Getopt::Long;
#use Data::Dumper;


my %options;
GetOptions(\%options, "name|n:s", "disk|d:i", "memory|m:i", "help");

if ($options{help}) {
    usage();

} elsif ($options{name} && $options{disk} && $options{memory}) {
    my $new_vm = KVM::CreateVM->new(name => $options{name}, disk => $options{disk}, memory => $options{memory});
    $new_vm->hypervisor_type('kvm');
    $new_vm->create_vm("--pxe --noautoconsole --graphics keymap=en-us --autostart");
    #print Dumper($new_vm);

} else {
    usage();
}



sub usage {
print <<EOF;

$0: Creates a new KVM guest.

Syntax: $0 [--help|--name=<VM-name> --disk=<size-in-MB> --memory=<size-in-MB>]

   --help   | -h  : This help message
   --name   | -n  : Name of the new virtual machine instance.
   --disk   | -d  : Disk Size in MB.
   --memory | -m  : Memory in MB.

EOF
exit 1;
}
