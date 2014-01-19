package CreateVM;


use POSIX;
use Carp;
use strict;


sub new {
    my $class = shift;
    my $self = {@_};
 
    bless ($self, $class);

    if ($< != 0) {
        print "Need root permission.\n";
        exit 1;
    }

    return $self;
}


sub hypervisor_type {
    my ( $self, $hypervisor_type ) = @_;
    
    $self->_hypervisor_ostype;

    if ( ($hypervisor_type =~ /^(kvm|xen|virtualbox|solaris_zone)$/)) {
        $self->{hypervisor_type} = $hypervisor_type;

    } else {
        croak "Unsupported hypervisor type specified: '$hypervisor_type'\n";
    }

    $self->virtual_machines_location;

    return $self->{hypervisor_type};

}


sub _hypervisor_ostype {
    my $self = shift;
    
    chomp(my $check_host_os = `uname`);

    if ($check_host_os eq 'Linux') {
        $self->{_hypervisor_ostype} = 'linux';
    } elsif ($check_host_os eq 'SunOS') {
        $self->{_hypervisor_ostype} = 'solaris';
    } else {
        croak "Your OS is not supported!";
    }
    
    return $self->{_hypervisor_ostype};
}


sub virtual_machines_location {
    my $self = shift;
    
    if ($self->{hypervisor_type} eq "virtualbox") {
        $self->{virtual_machines_location} = "$ENV{HOME}/VirtualBox VMs";

    } elsif ($self->{hypervisor_type} eq "kvm") {
        $self->{virtual_machines_location} = "/var/lib/libvirt/images";

    } elsif ($self->{hypervisor_type} eq "solaris_zone") {
        $self->{virtual_machines_location} = "rpool/zones/$self->{name}";

    } elsif ($self->{hypervisor_type} eq "xen") {
        $self->{virtual_machines_location} = "LOCATION-OF-XEN-dir";
    }

    return $self->{virtual_machines_location};

}


sub create_vm {
    my ($self, $vm_args) = @_;

    $self->{vm_args} = defined($vm_args) ? $vm_args : '';

    $self->virtual_machines_location;
    $self->hardware;
    $self->_resource_checks;
    
    chdir("$self->{virtual_machines_location}/$self->{name}");

    print "Creating virtual machine... \n\tName: $self->{name}\n\tMemory: $self->{memory}MB\n\t";
    print "Disk Size: $self->{disk}MB\n\t" if $self->{_hypervisor_ostype} ne 'solaris';
    ($self->{ostype}) ? print "OS Type: $self->{ostype}\n\n\n" : print "\n\n\n";

}


sub hardware {
    my $self = shift;

    my @hw = qw(00:1c:b3 00:1e:c2 00:1f:5b 00:1f:f3 00:21:e9 00:22:41 00:23:12 00:23:32 00:23:6c 00:23:df 00:24:36 00:25:00 00:25:4b 00:25:bc 00:26:08 00:26:4a 00:26:b0 00:26:bb 04:0c:ce 04:1e:64 10:93:e9 14:5a:05 24:ab:81 28:e7:cf 34:15:9e 40:30:04 40:d3:2d 44:2a:60 58:1f:aa 58:b0:35 60:fb:42 64:b9:e8 7c:6d:62 8c:58:77 90:84:0d 98:03:d8 a4:b1:97 a4:d1:d2 d4:9a:20 d8:30:62 d8:9e:3f f8:1e:df);
    my @mac_chars = ('a'..'f','0'..'9');
    
    $self->{hardware} = $hw[int(rand($#hw))];
    
    foreach (0..2) {
        my $random_str = $mac_chars[int(rand($#mac_chars))];
        my $random_str2 = $mac_chars[int(rand($#mac_chars))];
        $self->{hardware} .= ":$random_str$random_str2";
    }

    return $self->{hardware};
}


sub _resource_checks {
    my $self = shift;

    my ($available_disk_space, $available_memory); 

    if ($self->{_hypervisor_ostype} eq 'linux') {
        # checking available disk space    
        chomp($available_disk_space = `df -m |awk '\$NF~/^\\/\$/ {print \$4}'`); # /

        if ($self->{disk} >= $available_disk_space) {
            croak "Not enough space to create the virtual machine.\n\tAvailable: $available_disk_space MB\n";

        } elsif ($available_disk_space - $self->{disk} <= 2000) {
            croak "Warning: host machine is going to be critically low in disk space!!\n";

        }

        # Checking available memory
        chomp($available_memory = `free -m | grep buffers/cache |awk '{print \$NF}'`);
    
        if ($self->{memory} > $available_memory) {
            croak "Not enough memory available.\n\tFree memory: $available_memory MB\n";

        } elsif ($available_memory - $self->{memory} <= 512) {
            croak "Warning: If VM is created, available memory for host machine is going to be criticallly low!!\n\tFree memory: $available_memory MB\n";
        }
    }

    if ($self->{_hypervisor_ostype} eq 'solaris') {
        chomp(my $available_memory_in_kb = `vmstat |tail -1 |awk '{print \$5}'`);
        $available_memory = $available_memory_in_kb / 1000;

        # Disk usage is checked via Solaris::CreateZone::create_vm
    }


}


## These will get called by child clases ##

sub _hypervisor_bin {
    my ( $self, $_hypervisor_bin) = @_;
    
    chomp(my $check_bin = `which $_hypervisor_bin`);
    
    if ($check_bin eq "") {
        croak "$_hypervisor_bin was not found in this system.\n";
    } else {
        $self->{_hypervisor_bin} = $check_bin;
    }

    return $self->{_hypervisor_bin};

}

1;

__END__

=head1 NAME

CreateVM - Parent class to create new Virtual Machines, the easy way.

=head1 VERSION

This documentation refers to CreateVM version 0.2.

=head1 CONSTRUCTOR

=over 4

=item new( hash_ref );

Creates a new C<CreateVM> object.

=back

=head1 ATTRIBUTES

=head2 name

=head2 disk

=head2 memory

=head2 ostype

=head1 METHODS

=over 4

=item virtual_machines_location

    Read-only getter method used to retrieve the new VM instance's settings directory location.    

=over 4

=back

=item hypervisor_type
    
    Setter/getter method used to specify the guest VM hypervisor type.

=over 4

=back

=item create_vm

    Class method that prepares the system for the new VM.

=back

=over 4

=item hardware

    Read-only getter method that returns the newly created VM instance's MAC address (randomly generated).

=back

=over 4

=item _hypervisor_bin

    Private method used to determine the absolute path of the hypervisor binary.

=back

=over 4

=item _resource_checks

    Private method used to determine if the host machine has enough available disk and memory system resources.

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
