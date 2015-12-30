#!/usr/bin/perl
use strict;
use Image::Size;
use DBI;
use JSON;

my ($dbfile, $original, $square, $plain, $map, $output) = @ARGV;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");
create_poly($dbh, $original, '', $square, $plain, $map, $output);

sub new_loc($$$) {
    my ($scale, $off, $pixel) = @_;

    return int ($scale * ($pixel + $off) + 0.5);
}

sub plain($$$) {
    my ($plain_scale, $w_or_h, $loc) = @_;
    return $plain_scale * $loc;
}

sub create_poly($$$$$$) {
    my ($dbh, $original, $square, $plain, $map, $output) = @_;
    my $node_conn = $dbh->prepare(
        "SELECT src, dst FROM conns WHERE conns.src=? OR conns.dst=?");
    my $node = $dbh->prepare("SELECT title FROM article WHERE id=?");
    my @listeners;
    my @rect;

    open (my $f, "<", "$plain") or die ("unable to open $plain");
    open (my $out, ">$output") or die ("unable to open output $output");
    my $z = 5;    # Zoom Size

    my ($unmod_x, $unmod_y) = imgsize($original)
      or die ("Unable to find all.jpg");

    my $square = ($unmod_x > $unmod_y ? $unmod_x : $unmod_y);
    my $dim    = $square;
    my $pow    = -1;
    for (;;) {
        $pow++;
        my $i = 256 * (2**$pow);
        next if ($i < $dim);
        $dim = $i;
        last;
    }

    my ($new_x, $new_y) = ($square, $square);
    my $x_scale = $dim / $new_x;
    my $y_scale = $dim / $new_y;

    my ($x_scale, $y_scale) = (1, 1);
    my $x_off = ($new_x - $unmod_x) / 2.0 + ($dim - $square) / 2.0;
    my $y_off = ($new_y - $unmod_y) / 2.0 + ($dim - $square) / 2.0;

    my ($graph_w, $graph_h) = (0, 0);

    #print $out
    #  "/* img from $unmod_x,$unmod_y through $new_x,$new_y to $dim,$dim*/\n";

    my $visible = 0;

    my %polys;
    my ($plain_scale_x, $plain_scale_y) = (1, 1);    #72; #ppi

    foreach my $l (<$f>) {
        chomp $l;
        if ($l =~ /^node/) {
            my ($key, $id, $x, $y, $w, $h, $l, $style, $shape, $color,
                $fillcolor)
              = split (/ /, $l);
            my @coords = (
                $x + $w / 2,
                $y + $h / 2,
                $x - $w / 2,
                $y + $h / 2,
                $x - $w / 2,
                $y - $h / 2,
                $x + $w / 2,
                $y - $h / 2,
                $x + $w / 2,
                $y + $h / 2
            );
            my @points;
            my @xs;
            my @ys;
            my @c = @coords;
            my @d;
            while (my ($c1, $c2) = splice (@coords, 0, 2)) {
                push @d,
                  [
                    int (plain($plain_scale_x, $graph_w, $c1) + 0.5),
                    int (plain($plain_scale_y, $graph_h, $c2) + 0.5)
                  ];
                push @xs,
                  new_loc($x_scale, $x_off,
                    plain($plain_scale_x, $graph_w, $c1));
                push @ys,
                  new_loc($y_scale, $y_off,
                    plain($plain_scale_y, $graph_h, $c2));
            }
            $node_conn->execute($id, $id);
            my @pred = ();
            my @succ = ();
            while (my $row = $node_conn->fetchrow_hashref) {
                if ($row->{src} == $id) {
                    push @pred, $row->{dst};
                } else {
                    push @succ, $row->{src};
                }
            }
            push @rect, "$d[0][0],$d[0][1] $d[2][0],$d[2][1]";
            $polys{$id} = {
                'id'     => $id,
                'preds'  => \@pred,
                'succs'  => \@succ,
                'points' => {'xs' => \@xs, 'ys' => \@ys},
                'outs'   => {}
            };
        } elsif ($l =~ /^edge/) {
            my @items = split (/ /, $l);
            my $key   = shift @items;
            my $tail  = shift @items;
            my $head  = shift @items;
            my $n     = shift @items;
            my @points;
            my @xs;
            my @ys;

            for (my $i = 0; $i < $n; $i++) {
                my $c1 = shift @items;
                my $c2 = shift @items;
                push @xs,
                  new_loc($x_scale, $x_off,
                    plain($plain_scale_x, $graph_w, $c1));
                push @ys,
                  new_loc($y_scale, $y_off,
                    plain($plain_scale_y, $graph_h, $c2));
            }
            $polys{$tail}->{'outs'}->{$head} = {'xs' => \@xs, 'ys' => \@ys};

        } elsif ($l =~ /^stop/) {

            #EOF (ignore)
        } elsif ($l =~ /^graph/) {
            my ($key, $scale, $w, $h) = split (/ /, $l);
            $graph_w       = $w;
            $graph_h       = $h;
            $plain_scale_y = $unmod_y / $graph_h;
            $plain_scale_x = $unmod_x / $graph_w;
            print $unmod_y / $graph_h . " " . $unmod_x / $graph_w . "\n";
        } else {
            print "Unknown command $l\n";
        }
    }

    print $out to_json(\%polys);
    close $out;

}
1;
