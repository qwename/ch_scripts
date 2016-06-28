#!/usr/bin/perl -w

use strict;
use warnings;

use MIME::Base64 qw(decode_base64);
use JSON qw(to_json from_json);
use lib qw(./);
use ClickerHeroes::ImportScreen qw(fromAntiCheatFormat unSprinkle);
use Tools::JSON qw(searchJSON);

if (scalar(@ARGV) < 1) {
    die("Usage: $0 <FILE> [KEY]..\n");
}

my ($file, @keys) = @ARGV;

open(FILE, '<', $file) or die("Unable to open file: '$file'\n");

my $save;
{
    # undefine input file separator in this block;
    local $/;
    $save = <FILE>;
    close(FILE);
    unless(defined($save)) {
        die("Failed to read from file: '$file'");
    }
}
chomp($save);

my $jsonText;
my $jsonRef;

# Try to parse as JSON first
eval {
    $jsonRef = from_json($save, { utf8 => 1 });
};
# If it fails, assume it's in Clicker Heroes' format
if ($@) {
    # Check if TEXT_SPLITTER exists in the file, and check md5 hash if so.
    if (index($save, ClickerHeroes::ImportScreen::TEXT_SPLITTER) != -1) {
        $jsonText = decode_base64(fromAntiCheatFormat($save));
    } else {
        $jsonText = decode_base64(unSprinkle($save));
    }
    $jsonRef = from_json($jsonText, { utf8 => 1 });
}


# Print JSON save if no keys are supplied
if (scalar(@keys) == 0) {
    print to_json($jsonRef, { utf8 => 1, pretty => 1 });
    exit(0);
}

my %keyVals = map { $_ => 1 } @keys;
my %foundKeyVals = searchJSON($jsonRef, \%keyVals, '');

while (my ($key, $value) = each(%foundKeyVals)) {
    print "$key : ";
    if (ref($value) eq "HASH") {
        print to_json($value) . "\n";
    } else {
        print "$value\n";
    }
}
