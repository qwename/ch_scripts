#!/usr/bin/perl

use strict;
use warnings;

use JSON qw(from_json to_json);
use Path::Tiny;
use lib qw(./);
use Tools::JSON qw(searchJSON);

if (scalar(@ARGV) < 2) {
    die("Usage: $0 <FILE> <SECTION>\n");
}

my ($filename, $section) = @ARGV;
my $file = path($filename);

my $jsonText = $file->slurp;
my $jsonRef = from_json($jsonText, { utf8 => 1 });

my $heroesRef;
my $upgradesRef;

if ($section eq 'heroes' and exists($jsonRef->{heroes})) {
    $heroesRef = {};
    #print to_json($jsonRef->{heroes}, { utf8 => 1, pretty => 1 }) . "\n";
    my @keys = ( 'baseCost', 'baseAttack', 'name' );
    my %keyVals = map { $_ => 1 } @keys;
    while (my ($id, $data) = each %{$jsonRef->{heroes}}) {
        if ($id == 1) {     # Skip Cid
            next;
        }
        my %found = searchJSON($data, \%keyVals);
        $found{id} = $id;
        $heroesRef->{$id} = \%found;
        #print join(' ', $id, map { $found{$_} } @keys) . "\n";
    }
    print to_json($heroesRef, { utf8 => 1 }) . "\n";
}

if ($section eq 'upgrades' and exists($jsonRef->{upgrades})) {
    $upgradesRef = {};
    my @keys = ( 'heroId', 'heroLevelRequired',
                 'upgradeFunction', 'upgradeParams' );
    my %keyVals = map { $_ => 1 } @keys;
    while (my ($id, $data) = each %{$jsonRef->{upgrades}}) {
        my %found = searchJSON($data, \%keyVals);
        unless ($found{upgradeFunction} eq 'upgradeHeroPercent') {
            next;
        }
        $upgradesRef->{$found{heroId}}{$found{heroLevelRequired}} =
                                                        $found{upgradeParams};
    }
    print to_json($upgradesRef, { utf8 => 1 }) . "\n";
}

if (grep(/^$section$/, ('outsiders', 'ancients')) and
    exists($jsonRef->{$section})) {
    my $ref = {};
    my @keys = ( 'id', 'name' );
    my %keyVals = map { $_ => 1 } @keys;
    while (my ($id, $data) = each %{$jsonRef->{$section}}) {
        my %found = searchJSON($data, \%keyVals);
        $ref->{$found{id}} = $found{name};
    }
    my @sorted = sort { $a <=> $b } keys(%$ref);
    for my $id (@sorted) {
        my $shortName = (split(/, /, $ref->{$id}))[0];
        print "$id => '$shortName', ";
    }
    print "\n";
    print join(',', map { (split(/, /, $ref->{$_}))[0] } @sorted) . "\n";
}
