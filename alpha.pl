#!/usr/bin/perl
use strict;
use JSON;
use Image::Size;
use File::Slurp;
use Getopt::Long;

require 'gs_shared.pl';

my %args;
GetOptions(\%args, "target=s", "article=s", "file=s", "alpha=s",)
  or die "Invalid arguments!";

my %thresholds = (
    10  => 0.2,
    11  => 0.05,
    15  => 0.2,
    25  => 0.1,
    26  => 0.1,
    27  => 0.1,
    28  => 0.05,
    29  => 0.05,
    34  => 0.2,
    38  => 0.5,
    42  => 0.7,
    46  => 0.5,
    206 => 0.4,
    599 => 0.4,
    625 => 0.2,
);

my $file;
my $threshold = 0.5;
if (defined $args{file}) {
    $file = $args{file};
} else {
    my $json = from_json(read_file($args{article}));
    $file = "img/$json->{vicpic}";
    if ($thresholds{$json->{id}}) {
        $threshold = $thresholds{$json->{id}};
    } elsif ($json->{id} <= 48 || $json->{id} == 696) {
        $threshold = 10 / 255;
    } else {
        $threshold = 0.5;
    }

}
$threshold *= 100;
my ($width, $height) = imgsize($file);

my $extra = "";
if (-e $args{alpha}) {
    open my $f, "<$args{alpha}" or die ("Unable to open $args{alpha}\n");
    foreach my $l (<$f>) {
        chomp $l;
        $extra .= " -draw 'matte $l floodfill' ";
    }
}
my $w = $width - 1;
my $cmd =
  "convert '$file' -alpha set -channel RGBA -fuzz $threshold% -fill none -draw 'matte $w,0 floodfill' -draw 'matte 0,0 floodfill' $extra -shave 1x1 '$args{target}'";
print $cmd, "\n";
`$cmd`;
exit $?;
