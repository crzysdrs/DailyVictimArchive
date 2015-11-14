#!/usr/bin/perl
use strict;
use JSON;
use File::Slurp;

my ($target, $id, $article, $alpha_done) = @ARGV;
print $article, "\n";
my $json = from_json(read_file($article));

my $img = "_build/archive/img/$json->{vicpic}";

my $cmd =
  "convert $img $alpha_done -alpha Off -compose CopyOpacity -composite $target";
print $cmd, "\n";
`$cmd`;
