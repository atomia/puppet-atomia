#!/usr/bin/perl -w

use strict;
use warnings;

use WWW::Mechanize;
use Getopt::Long;
use JSON -support_by_pp;

my $daggre_uri = undef;
my $timeout = undef;
my $days = 0;
my $hours = 0;
my $minutes = 0;

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

GetOptions ( "uri=s" => \$daggre_uri ,
             "timeout=i" => \$timeout,
             "days=i" => \$days,
             "hours=i" => \$hours,
             "minutes=i" => \$minutes
           ) || exit_unknown("usage: $0 --uri http://212.247.189.107/g?a={auth}&o={instance-id}&latest=cpu_usage_ms --timeout 5");


exit_unknown("usage: $0 --uri http://212.247.189.107/g?a={auth}&o={instance-id}&latest=cpu_usage_ms --timeout 5") unless
        defined($daggre_uri) && defined($timeout);

my $mech = WWW::Mechanize->new();
exit_unknown("error constructing WWW::Mechanize browser object") unless defined($mech);

$mech->timeout($timeout) || exit_unknown("error setting timeout");
$mech->add_header('Accept-Encoding' => undef);

eval {
        $mech->get($daggre_uri) || exit_critical("error fetching daggre data");
        exit_critical("no content on given url") unless defined($mech->content);

        my $json = new JSON;
        exit_unknown("error constructing json object") unless defined($json);

        my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($mech->content);
        exit_unknown("decoding of json failed") unless defined($json_text);

        use DateTime;
        use DateTime::Format::ISO8601;
        my $time = DateTime->now(time_zone=>'GMT');

        my $last = DateTime::Format::ISO8601->parse_datetime($json_text->{last}->{start_of_span});

        my $interval = DateTime::Duration->new( days => $days, hours => $hours, minutes => $minutes );


        unless ($last + $interval > $time)
        {
                exit_critical("No recent stats are available: last is " . $json_text->{last}->{start_of_span});
        }
};

if ($@) {
        my $exception = $@;
        exit_critical($exception);
}

exit_ok("daggre has stats for the last $days days, $hours hours, $minutes minutes");
