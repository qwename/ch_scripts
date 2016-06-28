#!/usr/bin/perl -w
package Tools::JSON;

BEGIN {
    require Exporter;

    our $VERSION    = 1.0;
    our @ISA        = qw(Exporter);
    our @EXPORT     = qw();
    our @EXPORT_OK  = qw(searchJSON);
}

use strict;
use warnings;

use JSON qw(to_json);

sub searchJSON {
    my ($jsonRef, $keyRef, $hiearchy) = @_;
    unless (defined($hiearchy)) {
        $hiearchy = '';
    }
    my %found;
    while (my ($property, $value) = each(%$jsonRef)) {
        if (defined($value)) {
            if (exists($keyRef->{$property})) {
                my $key = $hiearchy eq '' ? '' : "${hiearchy}->";
                $key .= $property;
                if (ref($value) eq 'HASH') {
                    $found{$key} = to_json($value, { utf8 => 1 });
                } else {
                    $found{$key} = $value;
                }
            }
            if (ref($value) eq 'HASH') {
                my $subHiearchy = $hiearchy eq '' ? $property : "${hiearchy}->${property}";
                my %foundSub = searchJSON($value, $keyRef, $subHiearchy);
                # Merge hashes
                @found{keys(%foundSub)} = values(%foundSub)
            }
        }
    }
    return %found;
}

END {}

1;
