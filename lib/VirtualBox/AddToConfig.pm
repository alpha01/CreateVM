package VirtualBox::AddToConfig;


sub config {
    my $config = {@_};
    $config->{yaml_file} = defined($config->{yaml_file}) ? $config->{yaml_file} : "$ENV{'HOME'}/virtualbox/virtual-machines.yml";

    open(my $fh, '>>', $config->{yaml_file}) or die "Cannot open $config->{yaml_file}: $!";
    print {$fh} "    - $config->{name}\n";
    close($fh);
    
    print "Added $config->{name} to $config->{yaml_file}\n";
}

1;

__END__

=head1 NAME

VirtualBox::AddToConfig - Module used to add the newly created VM to a YAML config file.

=head1 VERSION

This documentation refers to VirtualBox::AddToConfig version 0.1.

=head1 SYNOPSIS

    use VirtualBox::AddToConfig;

    VirtualBox::AddToConfig->config(name => 'VM Name');
    # Or Optionally, specify yaml file. Defaults to ~/virtualbox/virtual-machines.yml.
    VirtualBox::AddToConfig->config(name => 'VM Name', yaml_file => '/path/to/yaml/file.yml');

=head1 Subroutine

=over 4

=item config( hash_ref );

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


