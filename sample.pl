#!/usr/bin/perl
use strict;
use Image::Magick;

my ($sample, $mask) = @ARGV;

my $file = Image::Magick->new;
$file->Read($mask);
open my $out, ">$sample";
my ($height, $width) = $file->Get('rows', 'columns');
my $str   = "";
my $count = 0;
for (my $x = 0; $x < $width; $x++) {
    for (my $y = 0; $y < $height; $y++) {
        my @rgb = $file->GetPixel('x' => $x, 'y' => $y);
        if ($rgb[0] > 0) {
            $str .= "$x $y ";
            $count++;
        }
    }
}

print $out $count, " ";
print $out $str;
close $out;
