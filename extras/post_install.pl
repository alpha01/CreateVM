#!/usr/bin/perl

# Running this after Kickstart/Debian netboot install.
# Written by Tony Baltazar. November 2013.
# email: root[@]rubyninja.org

use strict;

use Getopt::Long;

my %options;
GetOptions(\%options, "type|t:s", "name|n:s");


if ($options{help}) {
    usage();
} elsif ($options{type} && $options{name}) {

    post_cleanup();    

} else {
    usage();
}



sub post_cleanup {

    print "Shutting down $options{name}\n";

    if ($options{type} eq "virtualbox") {
        chomp(my $vboxmanage_bin = `which VBoxManage`);
        chomp(my $vboxheadless_bin = `which VBoxHeadless`);

        system("$vboxmanage_bin controlvm $options{name} poweroff && sleep 3 && $vboxmanage_bin modifyvm $options{name} --boot1 disk");

    } elsif ($options{type} eq "kvm") {
        chomp(my $virsh_bin = `which virsh`);

        system("$virsh_bin destroy $options{name}");
    } else {
        usage();
    }
    
    if ($? == 0) {
        print "Done.\n";
    } else {
        print "Failed to remove netboot on $options{name}!\n";
        exit 1;
    }
    
    print "Starting $options{name} ..\n";
    ($options{type} eq "virtualbox") ? system("$vboxheadless_bin -s $options{name} &") : system("$virsh_bin start $options{name}");

}


sub usage {
print <<EOF;

$0: Post installation cleanup ie; remove pxe boot and start the new VM.

Syntax: $0 [--help|--type=[virtualbox|kvm] --name=<VM-name>]

   --help   | -h  : This help message
   --type   | -d  : Hypervisor type (virtualbox|kvm).
   --name   | -n  : Name of the new virtual machine instance.

EOF
exit 1;
}
