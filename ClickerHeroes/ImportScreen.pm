#!/usr/bin/perl -w
# ui.ImportScreen
package ClickerHeroes::ImportScreen;

use strict;
use warnings;
use feature qw(state);

BEGIN {
    require Exporter;

    our $VERSION    = 1.0;
    our @ISA        = qw(Exporter);
    our @EXPORT     = qw();
    our @EXPORT_OK  = qw(TEXT_SPLITTER SALT
                         sprinkle unSprinkle
                         toAntiCheatFormat fromAntiCheatFormat);
}

use POSIX qw(floor);
use Digest::MD5 qw(md5_hex);

use constant TEXT_SPLITTER => 'Fe12NAfA3R6z4k0z';
use constant SALT => 'af0ik392jrmt0nsfdghy0';

sub sprinkle {
    state $alphabet = "1234567890qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM";
    my ($string) = @_;
    my @charArray = split('', $string);
    my @newCharArray;
    for my $i (0..$#charArray) {
        $newCharArray[$i*2] = $charArray[$i];
        $newCharArray[$i*2 + 1] = substr($alphabet, floor(rand() * (length($alphabet) - 1)), 1);
    }
    return join('', @newCharArray);
}

sub unSprinkle {
    my ($string) = @_;
    my @charArray = split('', $string);
    my @newCharArray;
    for (my $i = 0; $i < $#charArray; $i += 2) {
        $newCharArray[$i/2] = $charArray[$i];
    }
    return join('', @newCharArray);
}

sub toAntiCheatFormat {
    my ($string) = @_;
    return sprinkle($string) . TEXT_SPLITTER . getHash($string);
}

sub getHash {
    my ($string) = @_;
    return md5_hex($string . SALT);
}

sub fromAntiCheatFormat {
    my ($string) = @_;
    my @parts = split(TEXT_SPLITTER, $string);
    my $unsprinkled = unSprinkle($parts[0]);
    if (getHash($unsprinkled) ne $parts[1]) {
        die("Hash is bad\n");
    }
    return $unsprinkled;
}

END { }

1;
