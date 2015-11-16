#!/usr/bin/env perl

# Written by Tony Baltazar. November 2015.
# Email: root[@]rubyninja.org

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

use strict;
use warnings;

use File::Basename;
use lib dirname(__FILE__) . '/lib';
use LXC::CreateContainer;

use Getopt::Long;
#use Data::Dumper;


my %options;
GetOptions(\%options, "name|n:s", "template|t:s", "lxcpath|l:s", "help");

if ($options{help}) {
    usage();

} elsif ($options{name} && $options{template}) {
    my $new_vm = LXC::CreateContainer->new(name => $options{name}, template => $options{template});
    $new_vm->hypervisor_type('lxc');
    $new_vm->create_vm();
    #print Dumper($new_vm);

} else {
    usage();
}



sub usage {
print <<EOF;

$0: Creates a new LXC container.

Syntax: $0 [--help|--name=<Container-name> --type=<Template type>]

   --help       | -h  : This help message
   --name       | -n  : Name of container.
   --template   | -t  : Container template type.

  optionally,
   --lxcpath    | -p  : Alternate LXC path.

EOF
exit 1;
}
