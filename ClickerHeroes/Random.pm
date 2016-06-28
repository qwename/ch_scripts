#!/usr/bin/perl -w
# com.playsaurus.random.Random
package Random;

use strict;
use warnings;

use constant RAND_MAX => 2147483646;

sub new {
    my $class = shift;
    my $self = {
        seed => undef,
        numUses => 0 };
    bless $self, $class;
    return $self;
}

sub copy {
    my $self = shift;
    return bless { %$self }, ref $self;
}

sub srand {
    my ($self, $seed) = @_;
    if ($seed != int($seed)) {
        die("seed should be a whole number\n");
    }
    if ($seed <= 0 || $seed > RAND_MAX) {
        die("seed out of range\n");
    }
    $self->{seed} = $seed;
}

sub rand {
    my ($self) = @_;
    unless (defined($self->{seed})) {
        die("rand() called without a seed\n");
    }
    $self->{numUses}++;
    $self->{seed} = $self->{seed} * 16807 % (RAND_MAX + 1);
    return $self->{seed};
}

sub randFloat {
    my ($self) = @_;
    return $self->rand() / RAND_MAX;
}

sub boolean {
    my ($self, $chance) = @_;
    return $self->randFloat() < $chance;
}

sub isNaN {
    my $x = shift;
    return $x eq "nan";
}

sub range {
    my ($self, $min, $max) = @_;
    if (isNaN($min) or isNaN($max)) {
        die("min or max is NaN\n");
    }
    return $self->rand() % ($max - $min + 1) + $min;
}

sub integer {
    my ($self, $min, $max) = @_;
    if (!defined($max) or isNaN($max)) {
        $max = $min;
        $min = 0;
    }
    return POSIX::floor($self->range($min, $max));
}

sub weightedChoice {
    my ($self, %choices) = @_;
    my $sumWeight = 0;
    my @sortedWeights;
    for my $choice (keys(%choices)) {
        if ($choices{$choice} !~ /^\d+$/) {
            die("Random.weightedChoice received bad values\n");
        }
        $sumWeight += $choices{$choice};
        push(@sortedWeights, $choice)
    }
    @sortedWeights = sort { $a <=> $b } @sortedWeights;
    if ($sumWeight == 0) {
        die("Sum of weightedChoice options does not add up to anything meaningful\n");
    }
    my $selected = $self->rand() % $sumWeight + 1;
    $sumWeight = 0;
    for my $choice (@sortedWeights) {
        $sumWeight += $choices{$choice};
        if ($selected <= $sumWeight) {
            return $choice;
        }
    }
    die("Argument passed to Random.weightedChoice is invalid\n");
}

1;
