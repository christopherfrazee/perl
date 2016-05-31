#!/usr/bin/perl
use POSIX;
umask 550;
$http_log = '/root/file';
################# begin configuration section

open(HTTP_LOG, "<$http_log");
while (<HTTP_LOG>) 
{	
	$shortname = $_;
	chomp($shortname);
	$1_month = `find ${shortname}/Sites/*  -mtime +30 | wc -l`;
	$6_month = `find ${shortname}/Sites/* -mtime +180 | wc -l`;
	$12_month = `find ${shortname}/Sites/* -mtime +360 | wc -l`;
	chomp($1_month);
	chomp($6_month);
	chomp($12_month);
	print "$shortname $1_month $6_month $12_month \n";
}
