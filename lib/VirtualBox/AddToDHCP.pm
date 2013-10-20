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
