#!/usr/bin/perl -w

use strict;
use warnings;

use WWW::Mechanize;
use Getopt::Long;

my $hcp_uri = undef;
my $hcp_user = undef;
my $hcp_pass = undef;
my $timeout = undef;
my $string_match = undef;

sub exit_critical {
	my $message = shift;
	print "CRITICAL: $message\n";
	exit 2;
}

sub exit_unknown {
	my $message = shift;
	print "UNKNOWN: $message\n";
	exit 3;
}

sub exit_ok {
	my $message = shift;
	print "OK: $message\n";
	exit 0;
}

GetOptions (	"uri=s" => \$hcp_uri,
		"user=s" => \$hcp_user,
		"pass=s" => \$hcp_pass,
		"timeout=i" => \$timeout,
		"match=s" => \$string_match) || exit_unknown("usage: $0 --uri https://hcp.somehost.com/ --user someuser --pass somepass --timeout 5 --match somestring_to_match_after_successfull_login");

exit_unknown("usage: $0 --uri https://hcp.somehost.com/ --user someuser --pass somepass --timeout 5 --arg somestring_to_match_after_successfull_login") unless
	defined($hcp_uri) && defined($hcp_user) && defined($hcp_pass) &&
	defined($timeout) && defined($string_match);

my $mech = WWW::Mechanize->new();
exit_unknown("error constructing WWW::Mechanize browser object") unless defined($mech);

$mech->timeout($timeout) || exit_unknown("error setting timeout");
$mech->add_header('Accept-Encoding' => undef);

eval {
	$mech->get($hcp_uri) || exit_critical("error fetching hcp login page");
	
	exit_critical("PassiveStsEndpoint.aspx not found on login page") unless defined($mech->content) && $mech->content =~ /PassiveStsEndpoint\.aspx/;
	
	$mech->submit_form(
	        form_number => 1,
	        fields      => { username => $hcp_user, password => $hcp_pass }
	);
	
	exit_critical("error submitting login form") unless defined($mech->content);
	
	exit_critical("login of $hcp_user failed, got redirected back to login page") if $mech->content =~ /PassiveStsEndpoint\.aspx/;

	exit_critical("redirect page after login didn't contain RequestSecurityTokenResponseCollection") unless $mech->content =~ /RequestSecurityTokenResponseCollection/;
	
	$mech->submit_form(form_number => 1);

	my $content = $mech->content;	
	exit_critical("error submitting javascript redirect form with token") unless defined($content);

	unless ($content =~ /$string_match/) {
		exit_critical("timeout post javascript redirect but pre working HCP page") if $content =~ /timeout/;

		my $summary = substr($content, 0, 16);
		$summary =~ s/[\r\n]//g;

		exit_critical("match string not found after login, first 16 bytes where $summary");
	}
};

if ($@) {
	my $exception = $@;
	exit_critical($exception);
}

exit_ok("login successfull, all tests passed");
