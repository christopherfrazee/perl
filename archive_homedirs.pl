#!/usr/bin/perl
use POSIX;						# use POSIX compliance for time formatting
umask 770;
##########################################################
################# begin configuration section#############
##########################################################
$cn = "cn=users,dc=gresham,dc=k12,dc=or,dc=us";
$homedir_root = "/Volumes/hd";
$lock_file = "/tmp/archive_accounts.lock";
@school_code = ("cc","dc","dm","dx","eg","eo","gr","gh","ha","hi","hc","hd","kc","ng","pv","st","wg","wo","do");
@user_group = ("staf","stu");
$oldhomedirs = "/Volumes/hd/oldhomedirs";
chomp($hostname = `hostname`);
$ldapserver = "odm.gresham.k12.or.us";
print "Hostname is $hostname \n";
###############################################################################
############## begin multiple parallel process prevention section##############
###############################################################################

exit 0 if (-e "$lock_file");    			# exit if another instance of this program is running.
open(LOCK_FILE, ">$lock_file");
close(LOCK_FILE);
###########################################################
########## begin forking down directory tree############### 
###########################################################

foreach (@school_code)
	{
	$current_school_code = "$_";
	if (-d "${homedir_root}/${current_school_code}") 
	{
		print "Directory ${homedir_root}/${current_school_code} exists; traversing. . .  \n";
	}
	else 
	{
		print "No ${homedir_root}/${current_school_code}; skipping . . .  \n ";
	}

	foreach (@user_group)
		{

###################################################################
#### build list of all homedirectories in this school directory####
###################################################################

		$current_user_group = "$_";
		opendir(SHORTNAMES, "${homedir_root}/${current_school_code}/${current_user_group}");
		@CURRENT_SHORTNAMES = readdir(SHORTNAMES);
		closedir(SHORTNAMES);
########################################
#### go through accounts one by one#####
########################################
		foreach (@CURRENT_SHORTNAMES)
			{	
			if($_ =~ m/^(\.)/)	# skip file begain with a dot (system files)
				{
				next;
				}
			if($_ =~ m/^( )/)	# skip file bagain with space (misplaced group shared folders)
				{
				next;
				}
			else			# all else that does not apply to above two conditions are user homedirectories
				{	
				$a_shortname = "$_";
				$current_homedir = "${homedir_root}/${current_school_code}/${current_user_group}/${a_shortname}";
############################################
#### what does LDAP say about this user?####
############################################
				@ldap_out  = `ldapsearch -x -h odm.gresham.k12.or.us -LLL -b $cn "(uid=${a_shortname})" homeDirectory`;
				$current_school_path = "${homedir_root}/${current_school_code}/${current_user_group}";
				foreach $line (@ldap_out)
					{
					chomp($line);
					if ($line =~ m/homeDirectory/)	# process LDAP info that pertains to user homedirectories
						{
						
						if ($line =~ m/$hostname/ && $line =~ m/${current_school_path}/)	#   If this is true, legitimate user
							{
								next;
							}
						else 
							{
							archive_user();							#   If we get to here, then this is orphaned homedirectory
							}	
						}
					else	{ next; }		# don't process LDAP data that doesn't pertain to homedirectories 
					}
					
				}

			}
		}
	}

#############################
##pre-script exit cleanup  ##
#############################

unlink("$lock_file") || print $!;	# remove lock file

#############################
###Subroutines            ###
############################

sub archive_user 
	{                         
                                                
                                        print "ARCHIVEING: $current_homedir \n";
                                       `mkdir -p $oldhomedirs`;
                                       `chown root $oldhomedirs`;
                                       `chgrp wheel $oldhomedirs`;
                                       `chmod 770 $oldhomedirs`;
                                       `tar -czf ${oldhomedirs}/${a_shortname}.tar.gz $current_homedir`;
                                        print "DONE ARCHIVEING: $a_shortname \n";
                                        print "Removing: $current_homedir \n";
                                       `rm -rf $current_homedir`;
                                        print "Done removing $current_homedir . . .\n ";
	}
