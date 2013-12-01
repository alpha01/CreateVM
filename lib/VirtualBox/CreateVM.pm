package VirtualBox::CreateVM;


use File::Basename;
use lib dirname(__FILE__) . '../';
use CreateVM;


use strict;

our @ISA = qw(CreateVM);



sub create_vm {
    my $self = shift;

    $self->SUPER::create_vm;
    $self->_hypervisor_bin('VBoxManage');

    my @commands = (
            { createvm => "createvm --name '$self->{name}' --ostype $self->{ostype} --register 2>/dev/null" },
            { createhd => "createhd --filename '$self->{name}'.vdi --size $self->{disk} 2>/dev/null" },
            { configurehd => "storagectl '$self->{name}' --name 'SATA Controller' --add sata --controller IntelAhci --bootable on 2>/dev/null"},
            { attachdh => "storageattach '$self->{name}' --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium $self->{name}.vdi" },
            { modifyvm => "modifyvm '$self->{name}' --memory $self->{memory} --acpi on --boot1 net --nic1 bridged --bridgeadapter1 eth0 2>/dev/null" }
    );

    for (my $i=0; $i < scalar(@commands); $i++) {                
        foreach my $vbox_job (keys $commands[$i]) {
            $self->_vboxmanage_exec($commands[$i]{$vbox_job}, "$vbox_job failed!");
        }
    }

    $self->hardware;
}


sub _vboxmanage_exec {
    my ( $self, $cmd, $err_msg ) = @_;

    system("$self->{_hypervisor_bin} $cmd");
    if ($? != 0) {
        if ($cmd =~ /(createhd|configurehd|attachdh|modifyvm)/) {
            print "Cleaning up failed VM installation/configuration...\n\n";
            system("$self->{_hypervisor_bin} unregistervm '$self->{name}' --delete");
        }
        croak "$err_msg\n\t$self->{_hypervisor_bin} $cmd\n";
    }
}


sub _ostype {
    my $self = shift;

    chomp(my @ostype_list = `$self->{_hypervisor_bin} list ostypes|grep ID|awk '{print \$NF}'`);
    
    my $os_start = 0;
    my $output_ostype_string;

    foreach my $type (@ostype_list) {
        $output_ostype_string .= sprintf("%-20s %-20s", $type, "[ $os_start ]");

		if ($os_start % 3 == 0) {
			$output_ostype_string .= "\n";
		} else {
			$output_ostype_string .= "\t";
		} 

		$os_start += 1;  
    }

    if ( ($self->{ostype}) && (grep $_ eq $self->{ostype}, @ostype_list) ) {
		return $self->{ostype};

	} else {
		print 'Unknown OS type: ' . $self->{ostype} . "\n\n" if ($self->{ostype});
	
		print $output_ostype_string;
		print "\nNo OS type specified, choose the type ( default [38] ): ";
		chomp(my $os_input = <STDIN>);

		if (! $os_input) {
			$self->{ostype} = $ostype_list[38];
            return $self->{ostype};

 		} elsif ($os_input =~ /\D/) {
			croak "Invalid OS type: $os_input\n";

		} else {
			unless ($ostype_list[$os_input]) {
				croak "Invalid OS type: $os_input\n";
			
			} else {
				$self->{ostype} = $ostype_list[$os_input];
                return $self->{ostype};
			}
		}
	}
}


sub prompt {
    my $self = shift;
}


1;

__END__

=head1 NAME

VirtualBox::CreateVM - Class to create new VirtualBox Virtual Machines, the easy way.

=head1 VERSION

This documentation refers to VirtualBox::CreateVM version 0.1.

=head1 SYNOPSIS

    use VirtualBox::CreateVM;
    my $new_vm = VirtualBox::CreateVM->new(name => 'VM Name', disk => 8000, memory => 1024);
    $new_vm->create_vm;

=head1 CONSTRUCTOR

=over 4

=item new( hash_ref );

Creates a new C<VirtualBox::CreateVM> object.

=back

=head1 ATTRIBUTES

=head2 name

=head2 disk

=head2 memory

=head2 ostype

=head2 _vboxmanage_bin

=head1 METHODS

=over 4

=item virtual_machines_location( string );

    Setter/Getter method that specifies where the new VM instance's settings directory will be created in.    

=over 4

=back

=item hardware

    Read-only getter method that returns the newly created VM instance's MAC address.

=back

=over 4

=item create_vm

    Instance method that does all of the bulk work required to create the VM.

    Steps performed:
    # Create VM and registers it under VirtualBox.
    VBoxManage createvm --name 'VMName' --ostype VMOStype --register
    
    # Creates virtual hard disk that will be used by the new VM.
    VBoxManage createhd --filename 'VMName' --size DiskSizeInMB

    # Creates and cofigures a SATA storage controller on the VM. 
    VBoxManage storagectl 'VMName' --name 'SATA Controller' --add sata --controller IntelAhci --bootable on

    # Attaches the virtual hard disk to the SATA storage controller.
    VBoxManage storageattach 'VMName' --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium VMName.vdi

    # Sets memory, NIC and network boot settings.
    modifyvm 'VMName' --memory MemoryInMB --acpi on --boot1 net --nic1 bridged --bridgeadapter1 eth0

=back

=over 4

=item _vboxmanage_bin

    Private method which determines VBoxManage location.

=back

=over 4

=item _vboxmanage_exec

    Private method used to run the system commands.

=back

=over 4

=item _resource_checks

    Private method used to determine if the host machine has enough available disk and memory system resources.

=back

=over 4

=item  _ostype

    Private method used to verify the VM OS type (VBoxManage list ostypes) or set it to the deafult OS type, RedHat_64. 

=back

=head1 AUTHOR

Tony Baltazar <root@rubyninja.org>

=head1 LICENSE AND COPYRIGHT

Written by Tony Baltazar. October 2013.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
