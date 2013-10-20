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
