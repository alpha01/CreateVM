package LXC::CreateContainer;


use File::Basename;
use lib dirname(__FILE__) . '../';
use CreateVM;


use Carp;
use strict;

our @ISA = qw(CreateVM);



sub create_vm {
    my ($self, $vm_add_args) = @_;

    croak "ERROR: LXC containers can only be created in a GNU/Linux system!\n" if ($self->{_hypervisor_ostype} ne 'linux');

    $self->SUPER::create_vm($vm_add_args);
    $self->_hypervisor_bin('lxc-create');
    
    system("$self->{_hypervisor_bin} --name $self->{name} -t $self->{template} $self->{vm_args}");
    
    if ($? != 0) {
        croak "Failed to create LXC container!\n";
    } else {
        print "Successfully created LXC $self->{name} container.\n";
        return 1;
    }

}


1;

__END__

=head1 NAME

LXC::CreateContainer - Class to create an LXC container, the easy way.

=head1 VERSION

This documentation refers to LXC::CreateContainer version 0.2.

=head1 SYNOPSIS

    use LXC::CreateContainer;
    my $new_vm = LXC::CreateContainer->new(name => 'Container Name', template => 'ubuntu');
    $new_vm->hypervisor_type('lcx');
    $new_vm->create_vm;

=head1 CONSTRUCTOR

=over 4

=item new( hash_ref );

Creates a new C<LXC::CreateContainer> object.

=back

=head1 ATTRIBUTES

=head2 name

=head2 template


=head1 METHODS

=over 4

=item virtual_machines_location( string );

    Read-only getter method used to retrieve new VM instance's settings directory location.    

=back

=over 4

=item create_vm

    Instance method that does all of the bulk work required to create the container.

    Steps performed:
    # Creates LXC container. 
    lxc-creat --name <Container-name> -t <template> <additional options>

=back


=head1 AUTHOR

Tony Baltazar <root@rubyninja.org>

=head1 LICENSE AND COPYRIGHT

Written by Tony Baltazar. November 2015.

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
