#!/usr/bin/perl
##########################################################
################# begin configuration section#############
##########################################################
$output ="/var/log/afp_connections.log";
$tmpfile = '/var/tmp/connections.tmp';
$serveradmin = '/usr/sbin/serveradmin command afp:command = getConnectedUsers | grep ipAddress';
@network_ranges = ("10.88.","10.96.","10.98.","10.111.","10.87.","10.92.","10.117.","10.118.","10.113.","10.112.","10.102.","10.114.","10.76.","10.116.","10.100.","10.115.","10.119.","10.90.","10.89.");
$date = `/bin/date "+%x"`;
$time = `/bin/date "+%R"`;
chomp($date);
chomp($time);
$date =~ s/ /_/g;
$hostname = `/bin/hostname`;
$hostname =~ s/\..*//;
chomp($hostname);

@connections = ("$date","$time","$hostname");
###############################################################################
############## gather connections for each IP block connected to AFP ##########
###############################################################################
`$serveradmin > $tmpfile`;
foreach ( @network_ranges )

	{
		$current_network = $_;
		$active_connections = `cat $tmpfile | grep $current_network | wc -l`;
		chomp($active_connections);
		$active_connections =~ s/ //g;
		push(@connections, "$active_connections");
		$formated_connections = "@connections";
		$formated_connections =~ s/ /\,/g;
	}
open(OUTPUT, ">>$output");
print OUTPUT "$formated_connections \n";
close(OUTPUT);
