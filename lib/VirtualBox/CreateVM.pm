package VirtualBox::CreateVM;

use strict;
use POSIX;
use Carp;



sub new {
    my $class = shift;
    my $self = {@_};
 
    bless ($self, $class);

    $self->_resource_checks;
    $self->_vboxmanage_bin;
    $self->_ostype;

    return $self;
}


sub virtual_machines_location {
    my ( $self, $virtual_machines_location ) = @_;
    $self->{virtual_machines_location} = $virtual_machines_location if defined($virtual_machines_location);
    return $self->{virtual_machines_location};
}


sub create_vm {
    my $self = shift;

    print "Creating virtual machine... \n\tName: $self->{name}\n\tMemory: $self->{memory}MB\n\tDisk Size: $self->{disk}MB\n\tOS Type: $self->{ostype}\n\n\n";

    my @commands = (
            { createvm => "createvm --name '$self->{name}' --ostype $self->{ostype} --register 2>/dev/null" },
            { createhd => "createhd --filename '$self->{name}' --size $self->{disk} 2>/dev/null" },
            { configurehd => "storagectl '$self->{name}' --name 'SATA Controller' --add sata --controller IntelAhci --bootable on 2>/dev/null"},
            { attachdh => "storageattach '$self->{name}' --storagectl 'SATA Controller' --port 0 --device 0 --type hdd --medium $self->{name}.vdi" },
            { modifyvm => "modifyvm '$self->{name}' --memory $self->{memory} --acpi on --boot1 net --nic1 bridged --bridgeadapter1 eth0 2>/dev/null" }
    );

    chdir("$self->{virtual_machines_location}/$self->{name}");

    for (my $i=0; $i < scalar(@commands); $i++) {                
        foreach my $vbox_job (keys $commands[$i]) {
            $self->_vboxmanage_exec($commands[$i]{$vbox_job}, "$vbox_job failed!");
        }
    }

    $self->hardware;
}

sub hardware {
    my $self = shift;
    chomp(my $dotless_mac_address = `$self->{_vboxmanage_bin} showvminfo '$self->{name}'|grep MAC|awk '{print \$4}'`); 
    chop($dotless_mac_address); #gets rid of trailing comman (,)

    $self->{hardware} = join(':', grep {length > 0} split(/(..)/, $dotless_mac_address));
    return $self->{hardware};
}

sub _vboxmanage_bin {
    my $self = shift;
    chomp(my $_vboxmanage_bin = `which VBoxManage`);

    if ($_vboxmanage_bin eq "") {
        croak "VBoxManage was not found in this system.\n" 
    } else {
        $self->{_vboxmanage_bin} = $_vboxmanage_bin;
        return $self->{_vboxmanage_bin};
    }
}

sub _vboxmanage_exec {
    my ( $self, $cmd, $err_msg ) = @_;

    system("$self->{_vboxmanage_bin} $cmd");
    if ($? != 0) {
        if ($cmd eq 'createhd' || $cmd eq 'configurehd' || $cmd eq 'attachdh' || $cmd eq 'modifyvm') {
            print "Cleaning up failed VM installation/configuration...\n\n";
            system("$self->{_vboxmanage_bin} unregistervm '$self->{name}' --delete");
        }
        croak "$err_msg\n\t$self->{_vboxmanage_bin} $cmd\n";
    }
}


sub _resource_checks {
    my $self = shift;

    # checking available disk space    
    chomp(my $available_disk_space = `df -m |awk '\$NF~/^\\/\$/ {print \$4}'`); # /

    if ($self->{disk} >= $available_disk_space) {
        croak "Not enough space to create the virtual machine.\n\tAvailable: $available_disk_space MB\n";

    } elsif ($available_disk_space - $self->{disk} <= 2000) {
        croak "Warning: host machine is going to be critically low in disk space!!\n";

    }

    # Checking available memory
    chomp(my $available_memory = `free -m | grep buffers/cache |awk '{print \$NF}'`);
    
    if ($self->{memory} > $available_memory) {
        croak "Not enough memory available.\n\tFree memory: $available_memory MB\n";

    } elsif ($available_memory - $self->{memory} <= 512) {
        croak "Warning: If VM is created, available memory for host machine is going to be criticallly low!!\n\tFree memory: $available_memory MB\n";
    }

}

sub _ostype {
    my $self = shift;
    chomp(my @ostype_list = `$self->{_vboxmanage_bin} list ostypes|grep ID|awk '{print \$NF}'`);
    
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

1;
