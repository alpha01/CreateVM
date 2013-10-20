package VirtualBox::AddToDHCP;

sub new {
    my $class = shift;
	my $self = {@_};

	bless ($self, $class);
	return $self;
}

sub name {
	my ( $self, $name ) = @_;
	$self->{name} = $name if defined($name);
	return $self->{name};
}

sub hardware {
	my ( $self, $hardware ) = @_;
	$self->{hardware} = $hardware if defined($hardware);
	return $self->{hardware};
}

sub dhcp {
	my ( $self, $dhcp ) = @_;
	$self->{dhcp} = $dhcp if defined($dhcp);
	return $self->{dhcp};
}


sub add_to_dhcp {
	my ($self, $ssh_args) = @_;
    $self->{ssh_args} = $ssh_args if defined($ssh_args);
	print "\n\n\nAdding machine: $self->{name} to DHCP Server: $self->{dhcp}\n";
	system("ssh $self->{ssh_args} root\@$self->{dhcp} 'perl add_to_dhcpd.pl --name $self->{name} --hardware $self->{hardware}'");
}

1;

__END__

=head1 NAME

VirtualBox::AddToDHCP - Class used to push the new VM information to ISC-DHCPd.

=head1 VERSION

This documentation refers to VirtualBox::AddToDHCP version 0.1.

=head1 SYNOPSIS

    my $newvm = VirtualBox::AddToDHCP->new(name => 'VM Name', hardware => '08:00:27:4F:D3:EC', dhcp => '192.168.1.2');
    $newvm->add_to_dhcp;
    # Or
    my $newvm = AddToDHCP->new;
    $newvm->name('VM Name');
    $newvm->hardware('08:00:27:4F:D3:EC');
    $newvm->dhcp('192.168.1.2');
    $newvm->add_to_dhcp;

=head1 CONSTRUCTOR

=over 4

=item new( hash_ref );

Creates a new C<VirtualBox::AddToDHCP> object.

=back

=head1 ATTRIBUTES

=head2 name

=head2 hardware

=head2 dhcp

=head1 METHODS

=over 4

=item name( string );

    Public instance setter/getter method used to specify VM name.

=back

=over 4

=item hardware( string );

    Public instance setter/getter method used to specify VM's MAC address.

=back

=over 4

=item dhcp( string );

    Public instance setter/getter method used to specify the DHCP server.

=back

=head1 TO DO

    Add Net::ISC::DHCPd::Config code on add_to_dhcpd.pl to this class.

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
