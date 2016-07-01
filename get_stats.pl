#!/usr/bin/perl -w

use strict;
use warnings;
use bigint;
use Math::BigFloat ':constant';
use POSIX;

if (scalar(@ARGV) < 1) {
    die("Usage: $0 <FILE>\n");
}

my ($file) = @ARGV;

my @keys = (
    "numberOfTranscensions", "transcensionTimestamp",
    "numAscensionsThisTranscension", "startTimestamp",
    "unixTimestamp", "primalSouls", "totalHeroSoulsFromAscensions",
    "highestFinishedZone", "heroSoulsSacrificed",
    );

my $command = "./parse_save.pl \"$file\" " . join(' ', @keys);
my $output = `$command` or exit(1);

my @lines = split(/^/, $output);
my %stats;
my $delimiter = ' : ';
for my $line (@lines) {
    chomp($line);
    my @parts = split($delimiter, $line);
    my $key = shift(@parts);
    my $value = join($delimiter, @parts);
    $stats{$key} = $value;
}

while (my ($key, $value) = each %stats) {
    print "$key : $value\n";
}

my $msSinceTranscend = $stats{unixTimestamp} - $stats{transcensionTimestamp};
my $msSinceAscend = $stats{unixTimestamp} - $stats{startTimestamp};
my $minSinceTranscend = $msSinceTranscend / 1000.0 / 60;
my $minSinceAscend = $msSinceAscend / 1000.0 / 60;

my $totalHSInclAscends = $stats{totalHeroSoulsFromAscensions} +
                         $stats{primalSouls};
my $transcendHSPerMin = $totalHSInclAscends / $minSinceTranscend;
my $ascendHSPerMin = $stats{primalSouls} / $minSinceAscend;

my $currentAS = HSToAS($stats{heroSoulsSacrificed});
my $transcendAS = HSToAS($stats{totalHeroSoulsFromAscensions} +
                         $stats{primalSouls});
my $addAS = $transcendAS - $currentAS;
if ($addAS < 0) {
    $addAS = 0;
}

print <<"EOF";
Transcension HS/min: $transcendHSPerMin
Ascension HS/min: $ascendHSPerMin
Ancient Souls: $currentAS (+$addAS)
EOF

sub HSToAS {
    my ($hs) = @_;
    return POSIX::floor("5" * POSIX::log10($hs));
}

sub formatFloat {
    my ($x, $decimals) = @_;
    unless (defined($decimals) and $decimals =~ m/^\d+$/) {
        $decimals = 5;
    }
    return sprintf("%.${decimals}f ", $x);
}

my $plot = "$stats{numberOfTranscensions} " .
           "$stats{numAscensionsThisTranscension} " .
           "$stats{highestFinishedZone} " .
           formatFloat($minSinceTranscend) .
           formatFloat($minSinceAscend) .
           "$transcendHSPerMin " .
           "$ascendHSPerMin " .
           "$stats{heroSoulsSacrificed} " .
           "$totalHSInclAscends " .
           "$transcendAS " .
           "$addAS";

print STDERR "$plot\n";
