#!/usr/bin/perl
use strict;
use JSON;
require 'gs_shared.pl';
use Image::Size;
use Data::Dumper;
use File::Slurp;

sub handle_row($$) {
    my ($row, $y) = @_;
    my $max_height = 0;
    foreach my $r (@$row) {
        if ($r->{h} > $max_height) {
            $max_height = $r->{h};
        }
    }
    foreach my $r (@$row) {
        $r->{y_loc} = $max_height - $r->{h} + $y;
    }
    return $max_height;
}

my ($dbfile, $tmpdir, $outdir) = @ARGV;

my @accumulate = (
    [510, 501],
    [517, 513],
    [176, 164],
    [68,  59],
    [143, 135],
    [271, 264],
    [119, 109],
    [101, 93],
    [84,  76],
    [241, 94],
    [295, 287],
    [95,  82],
    [34,  13],
    [160, 153],
    [353, 346],
    [259, 255],
    [302, 147],
    [523, 373],
    [392, 386, 677],
    [444, 437],
    [432, 422],
    [459, 452],
    [466, 458],
    [285, 63],
    [478, 470, 651],
    [551, 481, 685],
    [494, 487],
    [514, 509],
    [526, 519],
    [557, 553],
    [601, 603],
    [387, 381],
    [403, 397],
    [335, 328],
    [596, 365, 356],
    [484, 476],
    [89,  70],
    [38,  17],
    [41,  23],
    [52,  39],
    [46,  31],
    [389, 515],
    [347, 340],
    [137, 129],
    [484, 476],
    [211, 205],
    [119, 109],

    #    [362,465],
    #    [349,525]
    [595, 419, 436],
    [490, 483],
    [247, 237],
    [42,  21],
    [253, 244],

    #[320,654],
    #[467,579],
    #[351,690],
    #[350,673],
    [298, 299, 300, 301],
    [311, 304],

    #    [393,411],
    [539, 529],
    [455, 448],    #,374],
    [500, 491, 611],
    [200, 145],
    [450, 422],
    [505, 496],
    [561, 556],
    [572, 567],
    [623, 615],
    [62,  49],
    [597, 450, 442],
    [598, 486],
    [188, 181],
    [408, 402],
    [206, 195],
    [154, 146],
    [148, 141],
    [341, 331],
    [235, 227],
    [229, 221],
    [323, 313],
    [472, 461],

    #   [440,672],
    [371, 363],
    [382, 379],
    [370, 405],
    [277, 270],
    [113, 104],
    [426, 418],
    [359, 352],

    #    [185,286],
    [697, 695, 694],
    [54,  284],
    [176, 164],
    [429, 438],
    [309, 317, 680],
    [414, 404],
    [329, 319],
    [275, 283],
    [398, 388],
    [74,  61],
    [125, 123],
    [182, 174],
    [289, 278],
    [265, 249],
    [194, 186],
    [217, 207],
    [639, 570],

    #    [100,282],
    #[321,631],
);

#411 link?
#425,362
#579 probably needs a link
#301 should link to 300

my %replace;
my %ids;
foreach my $a (@accumulate) {
    my $first = $a->[0];
    foreach my $a2 (@$a) {
        if ($a2 ne $first) {
            $replace{$a2} = $first;
        }
    }
    $ids{$first} = $a;
}
my @imgs;
foreach my $path (`ls ${tmpdir}/alpha/*.alpha.png`) {
    chomp $path;
    my ($width, $height) = imgsize($path);
    my ($id) = ($path =~ m/([0-9]+).alpha.png/);
    my %img = ('name' => $path, 'h' => $height, 'w' => $width, 'id' => $id);
    if (defined $ids{$id}) {
        $img{ids} = $ids{$id};
    } else {
        $img{ids} = [$id];
    }
    if ($path =~ /fargo|hotsoup|gabe/i) {

    } elsif (!defined $replace{$id}) {
        push @imgs, \%img;
    }
}

@imgs = sort {$b->{h} cmp $a->{h}} @imgs;

my $img_width = 5000;

my $x = 0;
my $y = 0;

my @row          = ();
my $pixel_indent = 30;
my $rows         = 0;
my $z_index      = 0;

my $title = "img/title.svg";
my ($title_w, $title_h) = imgsize($title);
my $title_scale = 8;
$title_h *= $title_scale;
$title_w *= $title_scale;
my $title_img = {
    x_loc => $img_width / 2 - $title_w / 2,
    y_loc => $y,
    name  => $title,
    h     => $title_h,
    w     => $title_w,
    id    => 'title'
};

$y += $title_h;
foreach my $i (@imgs) {
    $i->{z_index} = $z_index++;
    if ($x + $i->{w} > $img_width - $rows * $pixel_indent) {
        my $max_height = handle_row(\@row, $y);
        $rows++;
        @row = ();
        $x   = $rows * $pixel_indent;
        $y += $max_height / 3;
    }
    $i->{x_loc} = $x;
    $x += $i->{w} / 2;

    push @row, $i;
}

handle_row(\@row, $y);

$y += 200;
push @imgs, $title_img;

my $max_x = 0;
my $max_y = 0;

foreach my $i (@imgs) {

    #print $i->{name}, " x:", $i->{x_loc}, " y:", $i->{y_loc}, "\n";
    if ($max_x < $i->{x_loc} + $i->{w}) {
        $max_x = $i->{x_loc} + $i->{w};
    }

    if ($max_y < $i->{y_loc} + $i->{h}) {
        $max_y = $i->{y_loc} + $i->{h};
    }
}

$max_y += 100;

my $fargo = "${tmpdir}/alpha/fargo.alpha.png";
my ($w, $h) = imgsize($fargo);
push @imgs,
  {
    x_loc => $img_width / 2 - $w / 2,
    y_loc => $max_y,
    name  => $fargo,
    h     => $h,
    w     => $w,
    id    => 'fargo'
  };
my $gabe = "${tmpdir}/alpha/gabe.alpha.png";
my ($w, $h) = imgsize($gabe);
push @imgs,
  {
    x_loc => $img_width / 2 - 100 - $w / 2,
    y_loc => $max_y,
    name  => $gabe,
    h     => $h,
    w     => $w,
    id    => 'gabe'
  };
my $hotsoup = "${tmpdir}/alpha/hotsoup.alpha.png";
my ($w, $h) = imgsize($hotsoup);
push @imgs,
  {
    x_loc => $img_width / 2 + 100 - $w / 2,
    y_loc => $max_y,
    name  => $hotsoup,
    h     => $h,
    w     => $w,
    id    => 'hotsoup'
  };

$max_y += 100;

$max_x = int ($max_x);
$max_y = int ($max_y);

use Graphics::Magick;
my $w;

my $canvas = Graphics::Magick->new;
$w = $canvas->Set('size' => "${max_x}x${max_y}");
warn "$w" if "$w";
$w = $canvas->Read("xc:white");
warn "$w" if "$w";

my $count = 0;
my $total = scalar (@imgs);

my %loc;

my $z_index = 0;

my $square = ($max_x > $max_y ? $max_x : $max_y);
my $dim    = $square;
my $pow    = -1;
for (;;) {
    $pow++;
    my $i = 256 * (2**$pow);
    next if ($i < $dim);
    $dim = $i;
    last;
}

foreach my $i (@imgs) {
    $count++;
    print $count, "/", $total, " ", $i->{name}, "\n";
    my $comp = Graphics::Magick->new;
    $comp->Set('antialias' => 1);
    if ($i->{id} eq 'title') {
        $comp->Set('density' => 72 * $title_scale);
    }
    $comp->Set('size' => "$i->{w}x$i->{h}");
    $comp->Read($i->{name});
    if ($i->{id} ne 'title') {
        my $shadow = $comp->Clone();
        my $sigma  = 5;
        $shadow->Colorize(fill => 'gray');
        my $temp = $comp->Clone();
        $w = $temp->Composite('image' => $shadow, 'compose' => 'in');
        $shadow = $temp;    
        $shadow->Blur(
            'sigma'   => $sigma,
            'radius'  => 3,
            #'opacity' => 100,
            #'x'       => 0,
            #'y'       => 0
        );
        my $off = 0;
        my ($x_off, $y_off) = ($i->{x_loc} - $off, $i->{y_loc} - $off);
        $w = $canvas->Composite(
            'image'    => $shadow,
            'compose'  => 'over',
            'geometry' => "+$x_off+$y_off"
        );
    } else {
        $comp->Resize('geometry' => "$i->{w}x$i->{h}");
    }
    $w = $canvas->Composite(
        'image'    => $comp,
        'compose'  => 'over',
        'geometry' => "+$i->{x_loc}+$i->{y_loc}"
    );
    warn "$w" if "$w";
}

$w = $canvas->Write(filename => "${outdir}/reunion.png");
warn "$w" if "$w";

#http://karthaus.nl/rdp/js/rdp.js
sub properRDP($$) {
    my ($points, $epsilon) = @_;
    my $firstPoint = $points->[0];
    my $lastPoint  = $points->[scalar @$points - 1];
    if (scalar @$points < 3) {
        return $points;
    }
    my $index = -1;
    my $dist  = 0;
    for (my $i = 1; $i < scalar @$points - 1; $i++) {
        my $cDist =
          findPerpendicularDistance($points->[$i], $firstPoint, $lastPoint);
        if ($cDist > $dist) {
            $dist  = $cDist;
            $index = $i;
        }
    }

    if ($dist > $epsilon) {
        my @l1 = @{$points}[0 .. $index];
        my @l2 = @{$points}[$index .. scalar @$points - 1];
        my $r1 = properRDP(\@l1, $epsilon);
        my $r2 = properRDP(\@l2, $epsilon);
        my @rs;
        push @rs, @{$r1}[0 .. scalar @$r1 - 2];
        push @rs, @$r2;
        return \@rs;
    } else {
        return [$firstPoint, $lastPoint];
    }
}

sub findPerpendicularDistance($$$) {
    my ($p, $p1, $p2) = @_;
    my $result;
    my $slope;
    my $intercept;
    if ($p1->[0] == $p2->[0]) {
        $result = abs ($p->[0] - $p1->[0]);
    } else {
        $slope = ($p2->[1] - $p1->[1]) / ($p2->[0] - $p1->[0]);
        $intercept = $p1->[1] - ($slope * $p1->[0]);
        $result =
          abs ($slope * $p->[0] - $p->[1] + $intercept) / sqrt ($slope**2 + 1);
    }
    return $result;
}
use Data::Dumper;

my $x_img_off = int (($dim - $max_x) / 2);
my $y_img_off = int (($dim - $max_y) / 2);

my %composite_json;
foreach my $i (@imgs) {
    open my $sample, "<$tmpdir/alpha/$i->{id}.alpha_shape";
    my @points;
    my $x_off = int ($i->{x_loc});
    my $y_off = int ($i->{y_loc});
    my %end_points;
    my %start_points;
    my @lines;

    foreach my $line (<$sample>) {
        my ($x1, $y1, $x2, $y2) =
          ($line =~ m/([0-9\.]+),([0-9\.]+) ([0-9\.]+),([0-9\.]+)/i);

        $x1 = int ($x1);
        $x2 = int ($x2);
        $y1 = int ($y1);
        $y2 = int ($y2);
        $start_points{"$x1,$y1"} = [$x2, $y2];
    }

    while (scalar keys %start_points) {
        my @line;
        my $search_ref = \%start_points;
        my @keys       = keys %{$search_ref};
        my $search_key = $keys[0];
        my @first_pt   = split (/,/, $search_key);
        push @line, \@first_pt;

        while (defined $search_ref->{$search_key}) {
            my $next_key = $search_ref->{$search_key};
            delete $search_ref->{$search_key};
            push @line, \@{$next_key};
            $search_key = join (",", @{$next_key});
        }
        my $short_line = properRDP(\@line, 2);
        my @flattened = map {@$_} @$short_line;
        @flattened = map {int ($_)} @flattened;
        for ($x = 0; $x < scalar @flattened; $x += 2) {
            $flattened[$x] = $x_img_off + $x_off + $flattened[$x];
            $flattened[$x + 1] = $y_img_off + $y_off + $flattened[$x + 1];
        }
        push @lines, \@flattened;
    }

    my %json = (
        'z_index' => $i->{z_index},
        'lines'   => \@lines,
    );
    if (defined $i->{ids}) {
        my @sorted_ids = sort @{$i->{ids}};
        $json{ids} = \@sorted_ids;
    }
    $composite_json{$i->{id}} = \%json;
}

write_file("${outdir}/reunion.json",
    'var reunion_json = ' . to_json(\%composite_json));
