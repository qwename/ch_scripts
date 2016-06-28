#!/usr/bin/perl -w

use strict;
use warnings;

if (scalar(@ARGV) < 1) {
    die("Usage: $0 <FILE>\n");
}

my ($file) = @ARGV;

open(FH, "<$file") or die("Cannot open file: '$file'\n");
binmode(FH);

my $data = <FH>;
if ($data =~ m/json.{4}(\{.*)\x00$/) {
    print "$1\n";
}
