#!/usr/bin/perl
use POSIX;						# use POSIX compliance for time formatting
umask 750;
##########################################################
################# begin configuration section#############
##########################################################

$homedir_root="/Volumes/hd";
$lock_file="/tmp/fixpermissions.lock";
@school_code = ("dx","eg","wg");
@user_group = ("staf","stu");

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
	print "Fixing: ${homedir_root} & ${homedir_root}/${current_school_code} \n";
	`chmod 755 ${homedir_root}`;	# Set Permissions on top Level Share
	`chown root ${homedir_root}`;
       	`chgrp admin ${homedir_root}`; 
	`chmod 755 ${homedir_root}/${current_school_code}/`;  # set Permissions on top level school share point
	`chown root ${homedir_root}/${current_school_code}/`;
	`chgrp admin ${homedir_root}/${current_school_code}/`;
					
	foreach (@user_group)
		{
					# set permissions on each user type directory
		$current_user_group = "$_";
		print "Fixing: ${homedir_root}/${current_school_code}/${current_user_group} \n";
		`chown root ${homedir_root}/${current_school_code}/${current_user_group}`;
	 	`chgrp admin ${homedir_root}/${current_school_code}/${current_user_group}`;	
		`chmod 755 ${homedir_root}/${current_school_code}/${current_user_group}`;
		opendir(SHORTNAMES, "${homedir_root}/${current_school_code}/${current_user_group}");
		@CURRENT_SHORTNAMES = readdir(SHORTNAMES);
		closedir(SHORTNAMES);

#######################################################################
########### begin fixing permissions on homedir directory tree#########
#######################################################################

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
				print "Fixing ${a_shortname}:  ${current_homedir} \n";
				`chown -R $a_shortname $current_homedir`;		# fix owner of files
				`chmod -R -N ${current_homedir}`;				# remove all ACL's from files
				`chmod -R 755 ${current_homedir}`; 			# start out with fairly open permissions
				`chmod -R 700 ${current_homedir}/Desktop ${current_homedir}/Pictures ${current_homedir}/Documents ${current_homedir}/Library ${current_homedir}/Movies ${current_homedir}/Pictures ${current_homedir}/Music ${current_homedir}/Downloads`;		# lock down personal file directories
	   		        `chmod -R 755 ${current_homedir}/Public`;			# open up permissions on shared files folder
				`chmod -R +ai "group:guest allow read,execute,file_inherit,directory_inherit" ${current_homedir}/Sites`;  #	Force all files in Sites folder to be readable by guest (web server needs this).
				`chmod -R +a "everyone allow write,file_inherit,directory_inherit" ${current_homedir}/Public/Drop*`;
				`chmod -R +a "${a_shortname} allow read,write,execute,file_inherit,directory_inherit" ${current_homedir}/Public/Drop*`; # make all files in Drop Box removeable by home directory owner
				`chmod -R +a "everyone allow addfile,directory_inherit" ${current_homedir}/Public/Drop*`;
				`chmod 733 ${current_homedir}/Public/Drop*`;
				`chmod -R 644 ${current_homedir}/Public/Drop*/*`;
				
	
 		# Fix posix permissions on Drop Box contents.
				}

			}
		}
	}

#############################
##pre-script exit cleanup  ##
#############################

unlink("$lockfile") || print $!;	# remove lock file
