#!/usr/bin/perl -w
	
use POSIX;						# use POSIX compliance for time formatting
umask 550;
use Authen::Smb;
use Net::LDAP;
use Authen::Krb5::Simple;

################# begin configuration section

$input_file = "/usr/local/bin/password.txt";		# tab delimited file to use for obtaining user data
$lock_file = "/tmp/password_verify.lock";	
$pdc = 'odm.gresham.k12.or.us';
$bdc = "$pdc";
$domain = 'GRESHAM';
$ldap_root = "dc=gresham,dc=k12,dc=or,dc=us";

############## begin multiple parallel process prevention section

exit 0 if (-e "$lock_file");    			# exit if another instance of this program is running.
open(LOCK_FILE, ">$lock_file");
close(LOCK_FILE);

########## begin fifo logic

open(INPUT_FILE, "<$input_file") || die "Couldn't open: $input_file/$_\n";    # open file for reading
while (<INPUT_FILE>)
	{
	$input_file_line = $_;
	chomp($input_file_line);
	@user_info = split( '\t', $input_file_line );# put 1 line (1 user) of amdb info in array	
	$a_shortname = $user_info[0];
	$a_password = $user_info[1];
	chomp($a_shortname);
	chomp($a_password);
	NTLM_CHECK_PASS();
#	MD5_CHECK_PASS();
#	KRB5_CHECK_PASS();
	}
unlink($lock_file) ;

#############################
######## Sub Routines #######
#############################
sub KRB5_CHECK_PASS  # http://help-site.com/Programming/Languages/Perl/CPAN/Security_and_Encryption/Authen_Full/Authen-Krb5-Simple/Simple.pm/  & http://quark.humbug.org.au/publications/ldap/ldap_tut.html
{
	$krb = Authen::Krb5::Simple->new(realm => 'GRESHAM.K12.OR.US');
	$authen = $krb->authenticate($a_shortname, $a_password);
	print "Kerberose Authentication output: $authen \n";	
	unless($authen)	
	{
		$errmsg = $krb->errstr();
		print "User: $a_shortname authentication failed: $errmsg\n";
	}
	if($authen) 
	{
		print "${a_shortname}\t\tpassed test auth (KRB5)\n";	
	}

}
sub MD5_CHECK_PASS	# http://ldap.perl.org/FAQ.html
{
	#$dn = "uid=${a_shortname},ou=Users,$ldap_root";
	$dn = "uid=${a_shortname},cn=Users,$ldap_root";
	$ldap = Net::LDAP->new($pdc) or die "$@";  
	$mesg = $ldap->bind( $dn, password => $a_password );
	if ( $mesg->code )
		{
			print "${a_shortname}\t\t failed test auth (MD5)\n";
		}
	else	
		{		 
			print "${a_shortname}\t\t passed test auth (MD5)\n";
		}
	$ldap->unbind;
}
sub NTLM_CHECK_PASS #### http://search.cpan.org/~pmkane/Authen-Smb-0.91/Smb.pm
{
	$authResult = Authen::Smb::authen(	"$a_shortname",
						"$a_password",
						"$pdc",
						"$bdc",
						"$domain");
	print "authresult: $authResult \n";
	

	if($authResult == Authen::Smb::NO_ERROR)
	{
		print "${a_shortname}\t\t passed test auth (NTLM)\n";;
	}
	else 
	{
		print "${a_shortname}\t\t failed test auth (NTLM)\n";
	}
}
