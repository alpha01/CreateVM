package AddToDHCP;


use Net::ISC::DHCPd::Config;
use Net::Ping::External qw(ping);
use POSIX;
use Carp;

use strict;



sub new {
    my $class = shift;
	my $self = {@_};

	bless ($self, $class);

    $self->dhcpd_conf;
    $self->_check_dhcp_server;

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


sub network_range {
    my ($self, $network_range) = @_;
    $self->{network_range} = defined($network_range) ? $network_range : '192.168.1.20-129';
    return $self->{network_range};
}


sub dhcpd_conf {
    my ($self, $dhcpd_conf) = @_;
    $self->{dhcp_conf} = defined($dhcpd_conf) ? $dhcpd_conf : '/etc/dhcp/dhcpd.conf';
    return $self->{dhcpd_conf};
}


sub ssh_args {
    my ($self, $ssh_args) = @_;
    $self->{ssh_args} = $ssh_args if defined($ssh_args);
    return $self->{ssh_args};
}

sub add_to_dhcp {
	my $self = shift;
 
    my $tmpfile = strftime("$ENV{'HOME'}/.dhcpd.conf_%Y%m%d%H%S", localtime);

    my $dhcp_file_object = File::Remote->new(rsh => '/usr/bin/ssh', rcp => '/usr/bin/scp');
    $dhcp_file_object->copy("$self->{dhcp}:$self->{dhcpd_conf}", $tmpfile) or die $!;
    $self->_copy("")

    $self->network_range;
    $self->_get_ip($tmpfile);

    my $config_object = Net::ISC::DHCPd::Config->new(file => $tmpfile);
    $config_object->parse;

    if ($config_object->find_hosts({ name => $self->{name} }) ) {
        print "$self->{name} already exists!\n";
        exit 1;
    }

    $config_object->add_host({
        name => $self->{name},
        keyvalue => [{ name => 'hardware', value => "ethernet $self->{hardware}" },
            { name => 'fixed-address', value => $self->{_get_ip} }],
        #filename => [{ file => 'pxelinux.0' }],
        #options => [{name => 'namehere', value => 'valuehere'}],
    });

    $config_object->captured_to_args;
    $config_object->parse;

    print "Backing up $tmpfile to $self->{dhcp}:/etc/dhcp/backup-configs/ ...\n\n";
    $dhcp_file_object->copy("$self->{dhcp}:$self->{dhcpd_conf}", strftime("$self->{dhcp}:/etc/dhcp/backup-configs/dhcpd.conf_%Y%m%d%H%S", localtime)) or croack $!;

    print "Generating new dhcpd.conf file..\n";
    open(my $fh, '>', $tmpfile) or croak "Cannot open $tmpfile: $!";
    print {$fh} $config_object->generate_config_from_children;
    close($fh);

	print "\n\n\nAdding machine: $self->{name} to DHCP Server: $self->{dhcp}\n";
	system("ssh $self->{ssh_args} root\@$self->{dhcp} '/etc/init.d/isc-dhcp-server restart'");
    if ($? != 0) {
        croak "dhcpd restart failed!\n";
    } else {
        print "Successfully restarted dhcpd.\n\n";
        print "Add the following entries to DNS\n
            \t\t$self->{name}\tIN\tA\t$self->{_get_ip}\n
            \t\t" . ((split(/\./, $self->{_get_ip}))[-1] . ".1.168.192.in-addr.arpa.\tIN\tPTR\t$self->{name}.rubyninja.org.\n\n"); # Doing this shit manually for now
    }
}


sub _get_ip {
    my ($self, $file) = @_;

    $self->{network_range} =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}.)(\d{1,3})-(\d{1,3})$/;
    my ($network, $network_start, $network_end) = ($1, $2, $3);
    
    croak "Invalid dhcp network range: $self->{network_range}\n" unless ($network && $network_start && $network_end);
    
    for my $ip ($network_start .. $network_end) {
        my $alive = ping(hostname => "${network}${ip}");
        unless ($alive) {
            my $grep_search = `grep "${network}${ip}" $file`;
            if ($grep_search eq "" ) {
                $self->{_get_ip} = "${network}${ip}";
                return $self->{_get_ip};
                last;
            }
        }
    }
       #print "finish\n";
}

sub _check_dhcp_server {
    my $self = shift;

    unless (ping(host => $self->{dhcp})) {
        croak "Unable to talk to dhcp server: $self->{dhcp}\n";
    }

}

sub _copy {
    my ($self, $source, $destination) = @_;

    my $cmd_string = `scp $self->{ssh_args} root\@$self->{dhcp} '$cmd'`;
    if ($? != 0) {
        croak "_system_exec has shit itself:\n ssh $self->{ssh_args} $self->{dhcp} '$cmd'\n";
    } else {
        $self->{cmd_string} = $cmd_string;
        return $self->{cmd_string};
    }
     
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
