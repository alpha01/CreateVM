#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib';
use Solaris::CreateZone;

use Getopt::Long;
#use Data::Dumper;


my %options;
GetOptions(\%options, "name|n:s",  "memory|m:i", "help");

if ($options{help}) {
    usage();

} elsif ($options{name} && $options{memory}) {
    my $new_vm = Solaris::CreateZone->new(name => $options{name}, memory => $options{memory});
    $new_vm->hypervisor_type('solaris_zone');
    $new_vm->create_vm;
    #print Dumper($new_vm);

} else {
    usage();
}



sub usage {
print <<EOF;

$0: Creates a new Solaris Zone.

Syntax: $0 [--help|--name=<VM-name> --memory=<size-in-MB>]

   --help   | -h  : This help message
   --name   | -n  : Name of the new virtual machine instance.
   --memory | -m  : Memory in MB.

EOF
exit 1;
}
