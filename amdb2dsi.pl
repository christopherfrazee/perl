#!/usr/bin/perl
use POSIX;						# use POSIX compliance for time formatting
umask 550;

################# begin configuration section

$amdb_input_dir="/var/spool/opendir";			# tab delimited file to use for obtaining user data
$dsi_output_dir="/var/spool/dsimport";			# where we will put the converted "dsimport" file to store and upload to LDAP
$lock_file="/tmp/amdb2dsi.lock";	
$password_policy='isDisabled=0 isAdminUser=0 newPasswordRequired=0 usingHistory=0 canModifyPasswordforSelf=0 usingExpirationDate=0 usingHardExpirationDate=0 requiresAlpha=0 requiresNumeric=0 expirationDateGMT=4294967295 hardExpireDateGMT=4294967295 maxMinutesUntilChangePassword=0 maxMinutesUntilDisabled=0 maxMinutesOfNonUse=0 maxFailedLoginAttempts=0 minChars=0 maxChars=0 passwordCannotBeName=0 requiresMixedCase=0 notGuessablePattern=0 isSessionKeyAgent=0';
$admin_login='login';					# admin login to be used for ldap importing (ldap account)
$admin_pass='passsword';				# password to be used for ldap importing (ldap account password)
$exception = 'Got unexpected exception';		# dsimport exception error
$send_to = 'email@domain';				# who to email exception errors to
$send_cc = 'email@domain';				# wo to cc email exception errors to
$sendmail = '/usr/sbin/sendmail -t';			# path and arguments for piping to sendmail 
$sender = 'sender@domain';				# name of machine and login script runs as
############## begin multiple parallel process prevention section

exit 0 if (-e "$lock_file");    			# exit if another instance of this program is running.
open(LOCK_FILE, ">$lock_file");
close(LOCK_FILE);

########## begin fifo logic

opendir(AMDB_INPUT_DIR, $amdb_input_dir) || die "Couldn't open dir $amdb_input_dir";
@amdb_files = readdir(AMDB_INPUT_DIR);
closedir(AMDB_INPUT_DIR);

$size = @amdb_files; 			# get number of files in directory	
if ($size <= 2) 
	{				# if we only have . and .. then no files to process
		unlink("$lock_file");
		exit 0;
	}
else    {				# Otherwise, lets get started	
	
	open_output_file();
	chomp(@amdb_files);
	$newfile=0;             	# indicate we have not processed any data yet
	foreach (@amdb_files) 
		{
		if ( $_ =~ m/^(\.)/) 	# do nothing with  . and .. files
			{
			}
######## begin data processing logic 

		else 
			{
			$input_file = "$amdb_input_dir/$_";
			open(AMDB_FILE, "<$input_file")	|| die "Couldn't open: $amdb_input_dir/$_\n";	 # open file for reading
			$user_number = 1;
			while (<AMDB_FILE>) 
				{
				$amdb_file_line=$_;
				build_dsi_header();
				process_amdb_data();
				how_process_usr_logic();
				}
			
			close(AMDB_FILE);	
			unlink("$input_file");
			}		
		}
	}

##########   begin data import 
close(DSI_FILE);
print "Start dsimport\n";
$output = qx(dsimport -g $dsi_output_file /LDAPv3/127.0.0.1 O -u $admin_login -p $admin_pass );
exception_error_recovery();
print "dsimport output is: $output\n";
reset_password();
unlink("$lock_file");
##################   End of main program

##################   Begin file processing logic Subroutines
sub build_dsi_header
{
	if ($newfile==0 || $user_number==1 )        	# if have not processed any data yet, create header
        {

		printf DSI_FILE "0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 20 dsAttrTypeStandard:RecordName dsAttrTypeStandard:AuthMethod dsAttrTypeStandard:Password dsAttrTypeStandard:UniqueID dsAttrTypeStandard:PrimaryGroupID dsAttrTypeStandard:Comment dsAttrTypeStandard:RealName dsAttrTypeStandard:NFSHomeDirectory dsAttrTypeStandard:HomeDirectory dsAttrTypeStandard:UserShell dsAttrTypeStandard:HomeDirectoryQuota dsAttrTypeStandard:SMBHome dsAttrTypeStandard:SMBHomeDrive dsAttrTypeStandard:SMBScriptPath dsAttrTypeStandard:EMailAddress dsAttrTypeStandard:FirstName dsAttrTypeStandard:LastName dsAttrTypeStandard:Department dsAttrTypeNative:employeeNumber dsAttrTypeStandard:PasswordPolicyOptions \n";

               $newfile++;     				# header created, so start processing data

        }

}
sub process_amdb_data
{
	chomp($amdb_file_line);
	@amdb_user_info = split( '\t', $amdb_file_line );# put 1 line (1 user) of amdb info in array
							# make array elements more user friendly scalars
	$uid = $amdb_user_info[0];
        #########  map location number to location name ########        
	if ($amdb_user_info[1] == 2401)			{ $location = "location 1" }          
	elsif ($amdb_user_info[1] == 987) 		{ $location = "location 2" }              
        elsif ($amdb_user_info[1] == 1312)		{ $location = "location 3" }               
        elsif ($amdb_user_info[1] == 3553) 		{ $location = "location 4" }               
        elsif ($amdb_user_info[1] == 90) 		{ $location = "location 5" }               
        elsif ($amdb_user_info[1] == 91) 		{ $location = "location 6" }               
        elsif ($amdb_user_info[1] == 932) 		{ $location = "location 7" }               
        elsif ($amdb_user_info[1] == 10) 		{ $location = "location 8" }               
        elsif ($amdb_user_info[1] == 933) 		{ $location = "location 9" }               
        elsif ($amdb_user_info[1] == 941) 		{ $location = "location 10" }               
        elsif ($amdb_user_info[1] == 4740) 		{ $location = "location 11" }               
        elsif ($amdb_user_info[1] == 9740) 		{ $location = "location 12" }               
        elsif ($amdb_user_info[1] == 934) 		{ $location = "location 13" }               
        elsif ($amdb_user_info[1] == 986) 		{ $location = "location 14" }               
        elsif ($amdb_user_info[1] == 936) 		{ $location = "location 15" }               
        elsif ($amdb_user_infa[1] == 935) 		{ $location = "location 16" }               
        elsif ($amdb_user_info[1] == 3543) 		{ $location = "location 17" }               
        elsif ($amdb_user_info[1] == 937) 		{ $location = "location 18" }               
        elsif ($amdb_user_info[1] == 1313) 		{ $location = "location 19" }               
        elsif ($amdb_user_info[1] == 938) 		{ $location = "location 20" }               
        elsif ($amdb_user_info[1] == 939) 		{ $location = "location 21" }               
        elsif ($amdb_user_info[1] == 3577) 		{ $location = "location 22" }               
        elsif ($amdb_user_info[1] == 940) 		{ $location = "location 23" }
	elsif ($amdb_user_info[1] == 942)		{ $location = "location 24" }              
	else	{ $location = "unknown" };
	######### continue map variables to friendly names
        $last_name = $amdb_user_info[2];
        $first_name = $amdb_user_info[3];
        $fullname = "$first_name $last_name";		# generate our own fullname, amdb one is dirty
        $shortname = $amdb_user_info[5];
        $password = $amdb_user_info[6];
        $primary_group = $amdb_user_info[7];
        $nfs_home_path = $amdb_user_info[8];
        $homedirectory = $amdb_user_info[9];
        $shell = $amdb_user_info[10];
        $diskquota = $amdb_user_info[11];
        $comments = $amdb_user_info[12];
#       $smb_home = $amdb_user_info[13];		# not currently used
#       $smbhomedrive = $amdb_user_info[14];		# not currently used
#	$smb_login_script = $amdb_user_info[15];	# not currently used
        $smb_login_script = "login.bat";		# hard code this one, all are the same
        $email_address = $amdb_user_info[16];
#       $log_info = $amdb_user_info[17];
	$flags = $amdb_user_info[18];			# determines if username changes, username disable, enable, or just other record/attribute change
	$employeenumber = $amdb_user_info[19];
print "\t flags are: $flags \n";
	build_smb_path();
}
sub build_smb_path
{
	$network_home = $amdb_user_info[8];
        @network_home_dir = split( '/', $network_home);         # split the nfshomedir path into an array for easy parsing
        $stu_or_staf = "$network_home_dir[7]";                  # determine if student or staff user and store                       
        $server = "$network_home_dir[3]"; 			# get the homedirectory server name of user
        $server =~ s/.gresham.k12.or.us//;                      # strip off dns domain of homedirectory server
        $school = "$network_home_dir[6]";                       # get the user's school short namea
	$smbpath = "\\\\\\\\${server}\\\\${school}\\\\${stu_or_staf}\\\\$shortname";
	print "processing user: $shortname \n";
}
sub how_process_usr_logic
{
	$deactivate = 0;
	$new_pass_location = 1;
	$new_shortname = 2;
	$reactivate = 3;

	if ( $flags == $new_shortname ) 				# delete account / create new account
	{
		# Delete old user name	
		$old_shortname = qx(ldapsearch -x -h odm.gresham.k12.or.us -LLL -b cn=users,dc=gresham,dc=k12,dc=or,dc=us \'\(uidNumber=${uid}\)\' uid | grep ^uid | awk -F\" \" \'{print \$2}\');
		chomp($old_shortname);	
		print "\t User flagged for shortname change from $old_shortname to $shortname \n";
		$users_groups = qx(/usr/bin/id -G -n $old_shortname);	# get all LDAP groups user is assigned to
		chomp($users_groups);
		print "\t User belongs to groups: $users_groups \n";
		chomp($users_groups);
		@users_groups_array = split( ' ', $users_groups );
		foreach (@users_groups_array)				# remove user from all LDAP groups
		{
			$a_group = $_;
			$output3 = qx(/usr/bin/dscl -u $admin_login -P $admin_pass /LDAPv3/127.0.0.1 -delete /Groups/${a_group} GroupMembership ${old_shortname});
			print "\t Removing $old_shortname from $a_group: $ouptut3 \n";
		}							# remove the actual user from LDAP database
		$output3 = qx(/usr/bin/dscl -u $admin_login -P $admin_pass /LDAPv3/127.0.0.1 -delete /Users/${old_shortname});
                print "\t Removing user $old_shortname : $ouptut3 \n";
		add_user_to_dsi();
	}
	elsif ( $flags == $reactivate )	  				# reactivate account
	{
                print "\t Set user policy: $shortname to account enabled\n";
                $output1 = qx(/usr/bin/pwpolicy -a $admin_login -p $admin_pass -u $shortname -setpolicy "isDisabled=0 usingHardExpirationDate=0");
                chomp($output1);
                print "\t Enable account output: $output1 \n";
		add_user_to_dsi();
	}
	elsif ( $flags == $deactivate )					# deactivate account	
	{

		$disable_date = `/bin/date "+%m/%d/%y"`;
               	print "\t Set user policy: $shortname to account disabled \n";
               	$output1 = qx(/usr/bin/pwpolicy -a $admin_login -p $admin_pass -u $shortname -setpolicy "isDisabled=1 usingHardExpirationDate=1 hardExpireDateGMT=${disable_date}");
               	chomp($output1);
               	print "\t Disable account output: $output1 \n";
	}
	elsif ( $flags == $new_pass_location )
	{
        	if ( $user_number < 10 )                                # meter dsimport to 10 users at time.  Otherwise we have random corruption.
        	{
                	add_user_to_dsi();                              # Take the current users data gathered, and dump to new dsi file
                	$user_number++;
        	}
		elsif ( $user_number == 10)                             # every 10 users new dsimport file/session started to prevent corruption
        	{
       			############################ close out and import first 10 users
        		close(DSI_FILE);
                	print "Import to Directory $dsi_output_file \n"; # log that 10 users has been reached
                	$output = qx(dsimport -g $dsi_output_file /LDAPv3/127.0.0.1 O -u $admin_login -p "$admin_pass");        # import last 10 users
                	exception_error_recovery();
                	chomp($output);
                	print "\t dsimport completed with following messages: $output \n";
                	reset_password();                               # dsimport random password corrupts passwords / re-import w/h dscl

        		############################ re-initiate processing of user data
                	open_output_file();                             # open new dsimport file, and resets $user_number counter here
                	$newfile=0;                                     # enable new file (need file header logic)
                	$user_number=1;                                 # reset user_number logic
                	build_dsi_header();                             # create dsimport header on export file
                	process_amdb_data();                            # split user data into array for procesing`
                	build_smb_path();                               # Create users SMB path based off of NFSHome path
                	add_user_to_dsi();                              # Take the current users data gathered, and dump to new dsi file
		}
        		########################### wow there, error in logic somewhere
        	else    { die "Dieing, unexpected user number: $user_number   \n";}
	}
	else { die "Dieing, unexpected flag: $flags  \n";}
}
sub add_user_to_dsi						# print all of the gathered info about the user to the dsi file
{	
	printf DSI_FILE "$shortname:dsAuthMethodStandard\\:dsAuthClearText:$password:$uid:$primary_group:$comments:$fullname:$nfs_home_path:$homedirectory:$shell:$diskquota:$smbpath:S:$smb_login_script:$email_address:$first_name:$last_name:$location:$employeenumber:$password_policy\n";
}
sub open_output_file
{
	$date = `/bin/date "+%Y-%m-%d"`;
	$time = `/bin/date "+%H:%M.%S"`;
	chomp($date);
	chomp($time);
	$date_time = "${date}_${time}";
        $dsi_output_file="$dsi_output_dir/$date_time.dsi";
        open(DSI_FILE, ">$dsi_output_file") || die "Couldn't open: $dsi_output_dir/$datetime.dsi \n";   # open dsimport file to put amdb files data in
}
sub reset_password			# work around to defeat dsimport bug that changes user password to type "cryp" randomly.
{
open(DSI_FILE, "<$dsi_output_file") || die "Couldn't open: $dsi_output_dir/$datetime.dsi \n";   # open dsimport file to put amdb files data in
while(<DSI_FILE>)	
	{

        @dsi_user_info = split( ':', $_ );
        $ashortname = $dsi_user_info[0];
        $apassword = $dsi_user_info[3];
        chomp($ashortname);
        chomp($apassword);
	unless ($ashortname =~ m/0x0A 0x5C 0x3A 0x2C dsRecTypeStandard/ )		 # skip header of file (first line)	
		{
		print "\t Set user policy: $ashortname \n";
		$output1 = qx(/usr/bin/pwpolicy -a $admin_login -p $admin_pass -u $ashortname -setpolicy canModifyPasswordforSelf=0);
		$output2 = qx(/usr/bin/dscl -u $admin_login -P $admin_pass /LDAPv3/127.0.0.1 passwd /Users/${ashortname} "${apassword}");
		chomp($output1);
		chomp($output2);
		print "\t Fix password policy: $output1 \n";
		print "\t Fix pasword output: $output2 \n";
		}
	}
close(DSI_FILE);
}

sub exception_error_recovery
{
$counter = 0;
until ( $output !~ /$exception/ || $counter > 10 )
	{
	print "Received exception,($output) retrying import.";
	$output = qx(/usr/bin/dsimport -g $dsi_output_file /LDAPv3/127.0.0.1 O -u $admin_login -p "$admin_pass");        # import last 10 users
	$counter++;
        if ($counter == 10)
		{
		$subject = "ODM: ldap accounts import failure \n";
                $content = "On server odm.gresham.k12.or.us: the file  /var/spool/dsimport/$dsi_output_file \n failed to import AMDB changes into the LDAP database due to 10 consecutive errors. The error was: $output \n\n  please re-import the accounts listed in that file to keep LDAP & AMDB in sync. \n";
		open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
		print SENDMAIL "To: $send_to \n";
		print SENDMAIL "From: $sender \n";
		print SENDMAIL "CC: $send_cc  \n";
		print SENDMAIL "Subject: $subject \n";
		print SENDMAIL "Content-type: text/plain\n\n";
		print SENDMAIL "$content \n";
         	}
	}
}

