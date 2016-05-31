#!/usr/bin/perl
$admin_login='login';
$admin_pass='password';
open(FILE, "</tmp/users") ;

while (<FILE>) 
{
	chomp($_);
	$output1 = qx(/usr/bin/pwpolicy -a $admin_login -p $admin_pass -u $_ -setpolicy canModifyPasswordforSelf=0);
	print "set policy for $_ : $output1 \n ";
}
