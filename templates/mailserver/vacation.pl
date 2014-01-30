#!/usr/bin/perl -w

# ============== configuration ==============

our $db_host = '<%= @master_ip %>';
our $db_username = 'vmail';
our $db_password = '<%= @db_pass %>';
our $db_name     = 'vmail';
our $smtp_server = '127.0.0.1';
open (MYFILE, '>>/var/log/vacation.log');

# ============== preparation =================

use DBI;
use MIME::Base64;
use MIME::EncWords qw(:all);
use Email::Valid;
use strict;
use Mail::Sendmail;
use Getopt::Std;
use Log::Log4perl qw(get_logger :levels);
use Sys::Hostname;
my ($dbh, $stm, $from, $to, $cc, $replyto , $subject, $body, $messageid, $lastheader, $smtp_sender, $smtp_recipient, %opts, $spam, $test_mode, $logger);

# ============== filter unwanted mails ======

while (<STDIN>) {
        exit 0 if /^X-Loop:\s*Postfix\s+Admin\s+Virtual\s+Vacation/;
        exit 0 if /^Return-Path:\s*<>/;
        exit 0 if /^Precedence:\s*(auto-reply|junk)/;
}

# ============== main ========================

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$mon=$abbr[$mon];
my $host = hostname;
my $hindex=index($host,".");
$host=substr($host,0,$hindex);
my $index = rindex($ARGV[3],'@');
my $usr = substr($ARGV[3],0,$index+1);
my $dom = substr($ARGV[3],$index+12,length($ARGV[3]));
$from = $usr.$dom;
print MYFILE "--------------------------\n";
print MYFILE "$mon $mday $hour:$min:$sec\n";
print MYFILE "--------------------------\n";

my $dbh = DBI->connect("DBI:mysql:$db_name;$db_host", "$db_username", "$db_password") or print MYFILE "vacation: mysql: connection error: " . $dbh->errstr . "\n";
print MYFILE "vacation: mysql: connected to $db_name database on $db_host\n";
my $query = qq{SELECT subject,body FROM vacation WHERE email=?};
my $stm = $dbh->prepare($query) or print MYFILE "vacation: mysql: preparation error: " . $stm->errstr  . "\n";
$stm->execute($from) or print MYFILE "vacation: mysql: execution error:" . $stm->errstr . "\n";

my $rv = $stm->rows;
if ($rv == 1) {
        my @row = $stm->fetchrow_array;
        $subject = $row[0];
        $body = $row[1];
}

$to = $ARGV[1];
if ($to ne '') {
        my $vacation_subject = encode_mimewords($subject, 'Encoding'=> 'q', 'Charset'=>'iso-8859-1', 'Field'=>'Subject');
        my %mail;
        %mail = (
                'smtp' => $smtp_server,
                'Subject' => $vacation_subject,
                'From' => $from,
                'To' => $to,
                'MIME-Version' => '1.0',
                'Content-Type' => 'text/plain; charset=iso-8859-1',
                'Content-Transfer-Encoding' => 'base64',
                'Precedence' => 'junk',
                'X-Loop' => 'Postfix Admin Virtual Vacation',
                'Message' => encode_base64($body)
        );
        print MYFILE "vacation: replaiyng to: $from\n";
        sendmail(%mail);
        print MYFILE "vacation: Autoreply sent\n";
}
close (MYFILE);
