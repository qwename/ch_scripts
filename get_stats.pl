#!/usr/bin/perl -w

use strict;
use warnings;
use bigint;
use Math::BigFloat ':constant';
use POSIX;
use JSON qw(from_json);

if (scalar(@ARGV) < 1) {
    die("Usage: $0 <FILE>\n");
}

my ($file) = @ARGV;

my @keys = (
    "creationTimestamp",
    "numberOfTranscensions", "transcensionTimestamp",
    "numAscensionsThisTranscension", "startTimestamp",
    "unixTimestamp", "primalSouls", "totalHeroSoulsFromAscensions",
    "highestFinishedZone", "heroSoulsSacrificed", "outsiders", "ancients",
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
    if ($key =~ m/^(outsiders|ancients)/) {
        next;
    }
    print "$key : $value\n";
}

my $msSinceTranscend = $stats{unixTimestamp} - $stats{transcensionTimestamp};
my $msSinceAscend = $stats{unixTimestamp} - $stats{startTimestamp};
my $minSinceTranscend = $msSinceTranscend / 1000.0 / 60;
my $minSinceAscend = $msSinceAscend / 1000.0 / 60;
my $msSinceFirstClick = $stats{unixTimestamp} - $stats{creationTimestamp};
my $minSinceFirstClick = $msSinceFirstClick / 1000.0 / 60;

my $totalHSInclAscends = $stats{totalHeroSoulsFromAscensions} +
                         $stats{primalSouls};
my $transcendHSPerMin = $totalHSInclAscends / $minSinceTranscend;
my $ascendHSPerMin = $stats{primalSouls} / $minSinceAscend;

my $currentAS = HSToAS($stats{heroSoulsSacrificed});
my $transcendAS = HSToAS($stats{totalHeroSoulsFromAscensions} +
                         $stats{primalSouls});
my $totalAS = HSToAS($stats{heroSoulsSacrificed} +
                    $stats{totalHeroSoulsFromAscensions} +
                    $stats{primalSouls});
my $addAS = $totalAS - $currentAS;
if ($addAS < 0) {
    $addAS = 0;
}

my %outsiders = ( 1 => 'Xyliqil', 2 => "Chor'gorloth", 3 => 'Phandoryss',
                  4 => 'Borb', 5 => 'Ponyboy' );

my @outsiderLevels;
my $outsiderRef = from_json($stats{outsiders});
$outsiderRef = $outsiderRef->{outsiders};
my @outsiderSorted = sort { $a <=> $b } keys(%outsiders);
for my $id (@outsiderSorted) {
    my $name = $outsiders{$id};
    my $level = 0;
    if (defined($outsiderRef->{$id})) {
        $level = $outsiderRef->{$id}{level};
    }
    print "$name: $level, ";
    push(@outsiderLevels, $level);
}
print "\n";

my %ancients = ( 3 => 'Solomon', 4 => 'Libertas', 5 => 'Siyalatas',
                 6 => 'Khrysos', 7 => 'Thusia', 8 => 'Mammon', 9 => 'Mimzee',
                 10 => 'Pluto', 11 => 'Dogcog', 12 => 'Fortuna', 13 => 'Atman',
                 14 => 'Dora', 15 => 'Bhaal', 16 => 'Morgulis', 17 => 'Chronos',
                 18 => 'Bubos', 19 => 'Fragsworth', 20 => 'Vaagur',
                 21 => 'Kumawakamaru', 22 => 'Chawedo', 23 => 'Hecatoncheir',
                 24 => 'Berserker', 25 => 'Sniperino', 26 => 'Kleptos',
                 27 => 'Energon', 28 => 'Argaiv', 29 => 'Juggernaut',
                 30 => 'Iris', 31 => 'Revolc', );

my @ancientLevels;
my $ancientRef = from_json($stats{ancients});
$ancientRef = $ancientRef->{ancients};
my @ancientSorted = sort { $a <=> $b } keys(%ancients);
for my $id (@ancientSorted) {
    my $name = $ancients{$id};
    my $level = 0;
    if (defined($ancientRef->{$id})) {
        $level = $ancientRef->{$id}{level};
    }
    print "$name: $level, ";
    push(@ancientLevels, $level);
}
print "\n";

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

# Columns
# Transcensions,Ascensions,HZE,Mins Since Transcend, Mins Since Ascend,HS/min (Transcension),HS/min (Ascension),HS Sacrificed,HS (Transcension),HS (Ascension),Total AS,AS,+AS,Mins Since First Click,Xyliqil,Chor'gorloth,Phandoryss,Borb,Ponyboy,Solomon,Libertas,Siyalatas,Khrysos,Thusia,Mammon,Mimzee,Pluto,Dogcog,Fortuna,Atman,Dora,Bhaal,Morgulis,Chronos,Bubos,Fragsworth,Vaagur,Kumawakamaru,Chawedo,Hecatoncheir,Berserker,Sniperino,Kleptos,Energon,Argaiv,Juggernaut,Iris,Revolc
my $plot = "$stats{numberOfTranscensions} " .
           "$stats{numAscensionsThisTranscension} " .
           "$stats{highestFinishedZone} " .
           formatFloat($minSinceTranscend) .
           formatFloat($minSinceAscend) .
           "$transcendHSPerMin " .
           "$ascendHSPerMin " .
           "$stats{heroSoulsSacrificed} " .
           "$totalHSInclAscends " .
           "$stats{primalSouls} " .
           "$totalAS " .
           "$transcendAS " .
           "$addAS " .
           "$minSinceFirstClick " .
           join(' ', @outsiderLevels, @ancientLevels);

print STDERR "$plot\n";
