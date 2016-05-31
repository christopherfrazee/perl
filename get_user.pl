#!/usr/bin/perl
use POSIX;						# use POSIX compliance for time formatting


################# begin configuration section

$amdb_input_dir="/tmp/input";
$dsi_output_dir="/tmp/output";
$lock_file="/tmp/users.lock";

############## begin multiple parallel process prevention section

exit 0 if (-e "$lock_file");    			# exit if another instance of this program is running.
open(LOCK_FILE, ">$lock_file");
close(LOCK_FILE);

########## begin fifo logic

opendir(AMDB_INPUT_DIR, $amdb_input_dir) || die "Couldn't open dir $amdb_input_dir";
@amdb_files = readdir(AMDB_INPUT_DIR);
closedir(AMDB_INPUT_DIR);

$size = @amdb_files; 		# get number of files in directory	
if ($size <= 2) 
	{			# if we only have . and .. then no files to process
		unlink("$lock_file");
		exit 0;
	}
else    {			# Otherwise, lets get started	
	
	open_output_file();
	chomp(@amdb_files);
	$newfile=0;                                             # indicate we have not processed any data yet
	foreach (@amdb_files) 
		{
		if ( $_ =~ m/^(\.)/) 			# do nothing with  . and .. files
			{
			}
######## begin data processing logic 

		else 
			{
			$input_file = "$amdb_input_dir/$_";
			open(AMDB_FILE, "<$input_file")	|| die "Couldn't open: $amdb_input_dir/$_\n";	 # open file for reading
			while (<AMDB_FILE>) 
				{

					open_output_file();
       		                        process_amdb_data();                            # split user data into array for procesing`
                        	        add_user_to_dsi();                              # Take the current users data gathered, and dump to new dsi file
					}
				}
			
			close(AMDB_FILE);	
			unlink("$input_file");
			}		
		}
}
##########   begin data import 
close(DSI_FILE);
print "Start dsimport\n";
$output = qx(dsimport -g $dsi_output_file /LDAPv3/127.0.0.1 O -u odmdtech -p \'wsx\@4eqaz!3w\');
print "dsimport output is: $output\n";
print "Finish dsimport\n";
unlink("$lock_file");



sub process_amdb_data
{
               chomp($_);
                @amdb_user_info = split( '\t', $_ );            # put 1 line (1 user) of amdb info in array
								# make array elements more user friendly scalars
                $shortname = $amdb_user_info[5];


sub add_user_to_dsi						# print all of the gathered info about the user to the dsi file
{	
	printf DSI_FILE "$shortname\n";
}
sub open_output_file
{
        ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);  # set format of time  function
        $year += 1900;
        $datetime="${year}${mon}${mday}${hour}${min}${sec}";  # numeric time in variable for output file
        $dsi_output_file="$dsi_output_dir/$datetime.dsi";
        open(DSI_FILE, ">$dsi_output_file") || die "Couldn't open: $dsi_output_dir/$datetime.dsi \n";   # open dsimport file to put amdb files data in
        $user_number=0;
}
