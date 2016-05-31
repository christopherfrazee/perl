#!/usr/bin/perl -w
# ------------------------------------------------------------
# script:  ldapdeluser.pl
# Author:  Brad Marshall (bmarshal@pisoftware.com)
# Date:    20000203
#
# Purpose: Deletes a user from LDAP
#
# Copyright (c) 2000 Plugged In Software Pty Ltd.  All rights reserved.

# TODO
#   Remove the user from all groups they're in

use strict;
use Net::LDAP;
use Getopt::Std;
use Term::ReadKey;

use vars qw($opt_g);

my($uid);
my($gidnumber);
my($gidref);
my($cn);
my($dn);
my($result);
my($entry);

my($root) = "dc=pisoftware,dc=com";
my($host) = "ldap.staff.plugged.com.au";
my $exception = 0;

$SIG{'INT'} = $SIG{'QUIT'} = $SIG{'HUP'} = sub { $exception=1; };

# groupadd [-g gid [-o]] [-r] [-f] group

if (! $ARGV[0]) {
    print "$0: $0 username\n";
    exit 1;
}

if ($ARGV[0]) {
	$uid = $ARGV[0];
	if ($uid !~ /[a-z]{2,8}/) {
		die "Sorry, username must consist solely of letters and be between 3 and 8 characters.";
	}
} else {
	die "Sorry, you must specify a username";
}

$dn = &finduid;

#dn: cn=support,ou=Group,dc=pisoftware,dc=com
#objectclass: posixGroup
#objectclass: top
#cn: support
#gidnumber: 140

my($manager) = "cn=Manager,$root";
print "$manager\n";

print "Please enter LDAP Managers password: ";

ReadMode 'noecho';
my $password = ReadLine 0;
chomp $password;
ReadMode 'normal';
print "\n";

print "\$dn = $dn\n";

my($ldap) = Net::LDAP->new($host) or die "Can't bind to ldap: $!\n";

$ldap->bind(
            dn       => $manager,
            password => $password,
        );

if ($exception) {
	die "Caught a signal";
} else {
	$result = $ldap->delete ( $dn );
	&removegroup;
	$result->code && warn "failed to delete entry: ", $result->error ;
};


# Subroutines

sub finduid {
	my($ldap) = Net::LDAP->new($host) or die "Can't bind to ldap: $!\n";

	$ldap->bind;

	my($mesg) = $ldap->search( base => $root,
                               filter => '(objectclass=account)'
                             );

	$mesg->code && die $mesg->error;

	foreach $entry ($mesg->entries) {
		my($tmpuid) = $entry->get('uid')->[0];
		#print "\$tmpuid = $tmpuid\n";
		#print "$uid $tmpuid\n";
		if ($uid eq $tmpuid) {
			#print "Found it - \$tmpcn = $tmpcn\n";
			my($tmpdn) = $entry->dn;
			return $tmpdn;
		}
	}
	die "Sorry, can't find the user you want to delete.";
}

sub removegroup {
	my(@groups);
	my($group);

	my($ldap) = Net::LDAP->new($host) or die "Can't bind to ldap: $!\n";
	
	$ldap->bind;
	
	my($mesg) = $ldap->search( base => "dc=pisoftware,dc=com",
	                       filter => '(objectclass=posixGroup)');
	
	$mesg->code && die $mesg->error;
	
	foreach $entry ($mesg->entries) {
	    my($tmpcn) = $entry->get('cn');
	    my($tmpnum) = $entry->get('gidnumber');
	    my(@members) = $entry->get('memberuid');
	
	    #print "\@members = @members\n";
	    #print "Checking $tmpcn...";
	
	    my %t = ();
	    @t{@members} = 1;
	    if (exists $t{$uid}) {
	        #print "yes.";
	        # Push the cn onto an array
	        push @groups, $tmpcn;
	    }
	    #print "\n";
	}

	$ldap->unbind;

	my($authldap) = Net::LDAP->new($host) or die "Can't bind to ldap: $!\n";

	$authldap->bind(
            dn       => $manager,
            password => $password,
        );

	foreach $group (@groups) {
		my($tmpdn) = "cn=$group,ou=Group,$root";
		$authldap->modify( $tmpdn, delete => { memberuid => $uid } );
	}

	$authldap->unbind;
}

