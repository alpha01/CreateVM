package Solaris::CreateZone;


use File::Basename;
use lib dirname(__FILE__) . '../';
use CreateVM;

use Carp;
use strict;

our @ISA = qw(CreateVM);



sub pool {
    my ($self, $pool) = @_;

    my $zfs_pool_check;

    if (defined($pool)) {
        croak "Invalid ZFS storage pool\n" if ($pool =~ /^\d+$/); 
        $zfs_pool_check = $pool;
    } elsif ($self->{pool}) {
        $zfs_pool_check = $self->{pool};
    }

    if ($zfs_pool_check) {
        print "checking zpool ($zfs_pool_check)\n";
        my $zfs_pool_check_output = `zpool list $zfs_pool_check`;
        if ($? != 0) {
            croak "ZFS storage pool not found!!\n\n";
        } else {
            $self->{pool} = $zfs_pool_check;
        }
 
    } else {
        $self->{pool} = "rpool";
    }
    
    return $self->{pool};
}


sub virtual_machines_location {
    my ($self, $zfs_dataset) = @_;

    my $zfs_dataset_check;

    if (defined($zfs_dataset)) {
        $zfs_dataset_check = `zfs list $zfs_dataset 2>/dev/null`;
        if ($? !=0 ) {
            croak "Custom location requires its own dataset, ZFS dataset: $zfs_dataset not found in your system\n\n";
        } else {
            $self->{virtual_machines_location} = "$self->{pool}/$zfs_dataset";
        }
    } else {
        $self->{virtual_machines_location} = "$self->{pool}/$self->{name}";
    }

    return $self->{virtual_machines_location};

}


sub create_vm {
    my $self = shift;

    croak "ERROR: Zones can only be created in a Solaris system!\n" if ($self->{_hypervisor_ostype} ne 'solaris');

    $self->pool;
    $self->SUPER::create_vm;
    $self->_hypervisor_bin('zonecfg');

    my $get_available_pool_storage_output = `zpool list -o free $self->{pool} |tail -1`;
    $get_available_pool_storage_output =~ /([0-9]+?(.[0-9]+?))(B|K|M|G|T|P|E|Z)/;
    my ($available_storage, $storage_unit_type) = ($1, $3);

    # Will not install if their is less than 1GB available in the storage pool.
    if ($storage_unit_type =~ /(B|K|M)/) {
        my $verbose_shit = `zpool list $self->{pool}`;
        croak "Not enough space available in the ZFS database to create a zone!\n$verbose_shit\n";
    }
    
    system("zfs create -o mountpoint=/$self->{name} $self->{virtual_machines_location}");
    if ($? != 0) {
        print "Failed to create ZFS dataset!!!\n\n";
        exit 1;
    } else {
        print "Successfully created ZFS dataset.\n";
        system("zfs list $self->{virtual_machines_location}");
    }
    
    system("$self->{_hypervisor_bin} -z $self->{name} 'create; set zonepath=/$self->{name}; set autoboot=true; add capped-memory; set physical=$self->{memory}M; end'");
    if ($? != 0) {
        print "Failed to create Solaris zone!!!\n";
        exit 1;
    } else {
        print "Successfully created zone $self->{name}.\n";
    }


    chomp(my $zoneadm = `which zoneadm`);

    print "Installing Solaris zone $self->{name}. This may take a few minutes to complete.\n\n\n";
    system("$zoneadm -z $self->{name} install");

    print "\n\nStaring Solaris zone $self->{name}\n";
    system("$zoneadm -z $self->{name} boot");

}


1;

__END__

=head1 NAME

Solaris::CreateZone - Class to create a new Solaris zone, the easy way. (Using default template SYSdefault)

=head1 VERSION

This documentation refers to Solaris::CreateZone version 0.2.

=head1 SYNOPSIS

    use Solaris::CreateZone;
    my $new_vm = Solaris::CreateZone->new(name => 'Zone Name', memory => 1024);
    $new_vm->hypervisor_type('solaris_zone');
    $new_vm->create_vm;

=head1 CONSTRUCTOR

=over 4

=item new( hash_ref );

Creates a new C<Solaris::CreateZone> object.

=back

=head1 ATTRIBUTES

=head2 name

=head2 memory

=head1 METHODS

=over 4

=item pool( string );

    Getter/Setter method used to set a custom ZFS storage pool on where to install the zone and or to retrive the ZFS storage pool name.

=back

=over 4
    
=item virtual_machines_location( string );

    Getter/Setter method used to set the custom location of the ZFS dataset and or retrieve the ZFS dataset location.
    Defaults to rool/<zone-name> as the ZFS dataset.
    All ZFS datasets will have its mount point under /.    

=back

=over 4

=item create_vm

    Instance method that does all of the bulk work required to create the zone.

    Steps performed:
    # Creates the ZFS dataset.
    zfs create -o mountpoint=/<zone-name> rpool/<zone-name>

    # Creates the zone.
    zonecfg -z <zone-name> 'create; set zonepath=/<zone-name>; set autoboot=true; add capped-memory; set physical=<MemoryInMB>M; end'"

    # Installs the zone.
    zoneadm -z <zone-name> install

    # Starts the zone.
    zoneadm -z <zone-name> boot

=back


=head1 AUTHOR

Tony Baltazar <root@rubyninja.org>

=head1 LICENSE AND COPYRIGHT

Written by Tony Baltazar. January 2014.

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
