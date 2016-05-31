#!/usr/bin/perl -w
$subject = "this is a test message\n";
$content = "this is a test message\n";
$send_to = 'receiver@domain.com';
$sender = 'sender@domain.com';
$sendmail = '/usr/sbin/sendmail -t';
open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
print SENDMAIL "To: $send_to \n";
print SENDMAIL "From: $sender \n";
print SENDMAIL "Subject: $subject \n";
print SENDMAIL "Content-type: text/plain\n\n";
print SENDMAIL "$content \n";
close(SENDMAIL);

