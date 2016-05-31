#!/usr/bin/perl
$admin_login='login';                                # admin login to be used for ldap importing (ldap account)
$admin_pass='password'; 
$ldap_server='servername.domain.com';
$cn='users,dc=gresham,dc=k12,dc=or,dc=us';
$uid=1026;
$output3 = qx(ldapsearch -x -LLL -h $ldap_server  -b cn=$cn \'\(uidNumber=${uid}\)\' uid | grep ^uid | awk -F\" \" \'{print \$2}\'); 


#$output3 = 
print "Output is: $output3 \n"

