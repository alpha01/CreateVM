package KVM::CreateVM;


use File::Basename;
use lib dirname(__FILE__) . '../';
use CreateVM;


use strict;

our @ISA = qw(CreateVM);



sub _virtual_machines_location {
    my $self = shift;
    
    $self->{_virtual_machines_location} = "/var/lib/libvirt/images";
    return $self->{_virtual_machines_location};

}

sub create_vm {
    my $self = shift;

    $self->SUPER::create_vm;
    $self->_hypervisor_bin('virt-install');
    
    my $size_in_gb = $self->{disk} / 1000; #Need to convert MB to GB
 
    system("$self->{_hypervisor_bin} --name $self->{name} --ram $self->{memory} --disk path=$self->{_virtual_machines_location}/$self->{name}.img,size=$size_in_gb -w bridge=br0,mac=$self->{hardware} --pxe --noautoconsole --graphics keymap=en-us --autostart");

    if ($? != 0) {
        croak "Failed to create KVM guest!\n";
    } else {
        print "Successfully created $self->{name}\n";
        return 1;
    }

}


1;

__END__

=head1 NAME

KVM::CreateVM - Class to create new KVM Virtual Machines, the easy way.

=head1 VERSION

This documentation refers to KVM::CreateVM version 0.2.

=head1 SYNOPSIS

    use KVM::CreateVM;
    my $new_vm = KVM::CreateVM->new(name => 'VM Name', disk => 8000, memory => 1024);
    $new_vm->hypervisor_type('kvm');
    $new_vm->create_vm;

=head1 CONSTRUCTOR

=over 4

=item new( hash_ref );

Creates a new C<KVM::CreateVM> object.

=back

=head1 ATTRIBUTES

=head2 name

=head2 disk

=head2 memory

=head2 ostype

=head1 METHODS

=over 4

=item virtual_machines_location( string );

    Read-only getter method used to retrieve new VM instance's settings directory location.    

=back

=over 4

=item create_vm

    Instance method that does all of the bulk work required to create the VM.

    Steps performed:
    # Creates KVM guest VM. 
    /usr/bin/virt-install --name VM-name --ram <ram> --disk path=/var/lib/libvirt/images/<VM-name>.img,size=<disk-size> -w bridge=br0,mac=<random-generated-mac> --pxe --noautoconsole --graphics keymap=en-us

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
