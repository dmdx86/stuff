#!/usr/bin/perl
use strict;

#Potentially useful script to read the memory.stat and other memory related files on a cgroups V1 system and convert values from bytes to megabytes for easier reading
#Note: Displays the total_* values from memory.stat only (i.e. includes descendant cgroup statistics in the value)
#Also gather some memory data from other sources and display it

#mainly intended to analyze K8S memory usage

open(MEM_STAT, "/sys/fs/cgroup/memory/memory.stat");

my $total_inactive_file = 0;

foreach my $line (<MEM_STAT>)
{
    chomp $line;
    my ($thingy, $size) = split(/ /, $line);
    next unless ($thingy =~ /total/);
    if ($thingy eq 'total_inactive_file')
    {
        $total_inactive_file = $size;
    }
    $size = $size / 1000000;
    printf("%30s:\t%6dM\n", $thingy, $size);
}

my $mem_usage_bytes = `cat /sys/fs/cgroup/memory/memory.usage_in_bytes`;
chomp($mem_usage_bytes);
my $mem_usage_megabytes = $mem_usage_bytes / 1000000;
printf("%30s:\t%6dM\n", "memory_usage_in_bytes", $mem_usage_megabytes);

my $mem_max_usage_bytes = `cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes`;
chomp($mem_max_usage_bytes);
my $mem_max_usage_megabytes = $mem_usage_bytes / 1000000;
printf("%30s:\t%6dM\n", "memory_max_usage_in_bytes", $mem_max_usage_megabytes);

my $working_set_bytes     = ($mem_usage_bytes - $total_inactive_file);
my $working_set_megabytes = $working_set_bytes / 1000000;
printf("%30s:\t%6dM\n", "working_set", $working_set_megabytes);

close(MEM_STAT);

my @output    = `ps -e -o pid,rss --no-header | sort -nk2`;
my @processes = ();

# Parse the output and store process information in the array
foreach my $line (@output)
{
    chomp $line;
    $line =~ s/^\s+//g;
    my ($pid, $rss) = split /\s+/, $line;
    push @processes,
      {
        pid => $pid,
        rss => $rss,
      };
}

my $rss_tot = 0;
foreach my $process (@processes)
{
    $rss_tot += $process->{rss};
    my $pid = $process->{pid};
    my $rss = $process->{rss};
}

$rss_tot /= 1000;
printf("%30s: %6dM\n", "rss total from ps cmd", $rss_tot);
close(MEM_STAT);
