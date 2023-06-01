#!/usr/bin/perl

#Simple perl script to read /proc/meminfo and convert the values to megabytes

use strict;
open(MEM_INFO, "/proc/meminfo");

foreach my $line (<MEM_INFO>)
{
    chomp $line;
    $line =~ s/\s+/ /g;
    $line =~ s/://g;
    $line =~ s/ kB//g;
    my ($thingy, $size) = split(/ /, $line);
    $size = $size / 1000;
    printf("%20s:\t%10dM\n", $thingy, $size);
}

close(MEM_INFO);
