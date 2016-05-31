#!/usr/bin/perl
use POSIX;
umask 550;
$http_log = '/root/darrin.log';
################# begin configuration section

open(HTTP_LOG, "<$http_log");
while (<HTTP_LOG>) 
{	
	$input = $_;
	chomp($input);
	$input =~ s/ HTTP//;
	$input =~ s/^\s+|\s+$//g;
	@http_log_data = split( '/', $input);	
	$shortname = $http_log_data[3];
	chomp($shortname);
	print "$shortname \n";
}
