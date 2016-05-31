#!/usr/bin/perl
use POSIX;						# use POSIX compliance for time formatting
umask 770;
##########################################################
################# begin configuration section#############
##########################################################

$homedir_root="/Volumes/hd";
$lock_file="/tmp/archive_accounts.lock";
@school_code = ("cc","dc","dm","dx","eg","eo","gr","gh","ha","hi","hc","hd","kc","ng","pv","st","wg","wo","do");
@user_group = ("staf","stu");
$oldhomedirs = "/Volumes/hd/oldhomedirs";
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

#### build list of all homedirectories in this school directory
		$current_user_group = "$_";
		opendir(SHORTNAMES, "${homedir_root}/${current_school_code}/${current_user_group}");
		@CURRENT_SHORTNAMES = readdir(SHORTNAMES);
		closedir(SHORTNAMES);
#### go through accounts one by one
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
			else			# fix all else that does not apply to above two conditions
				{	
				$a_shortname = "$_";
				$current_homedir = "${homedir_root}/${current_school_code}/${current_user_group}/${a_shortname}";
##### get the uid of the homedirectory
				$uid = (stat $current_homedir)[4];
##### query what the shortname of that uid is	
				$user = (getpwuid $uid)[0];
				if ($user =~ m/${a_shortname}/ )  # if directory owner does not match shortname, then archive
					{
					}
				else 
					{	
					print "ARCHIVEING. . . SHORTNAME: $a_shortname USER: $user \n";
					`mkdir -p $oldhomedirs`;
					`chown root $oldhomedirs`;
					`chgrp wheel $oldhomedirs`;
					`chmod 770 $oldhomedirs`;
					`tar -czf ${oldhomedirs}/${a_shortname}.tar.gz $current_homedir`;	
					print "DONE ARCHIVEING: $a_shortname \n";
					print "Removing old homedir: $a_shortname \n";
					`rm -rf $current_homedir`;	
					print "Done removing. . .\n ";

					}
				}

			}
		}
	}

#############################
##pre-script exit cleanup  ##
#############################

unlink("$lock_file") || print $!;	# remove lock file
