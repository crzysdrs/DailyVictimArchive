#!/usr/bin/perl -w
#
# vim:ts=4:sw=4:ai:et:si:sts=4:sta
#
# Copyright 2008 Chris Petersen and iFloor.com
#
# This application is distributed under the GNU Lesser GPL version 2 or later:
# http://www.gnu.org/licenses/lgpl.html
#

=head1 create_tiles.pl

Export tiles for use with Google Maps API for image zoom.

This breaks up an image into "zoom" tiles that can be used as a custom map
type, as described here:

  http://code.google.com/apis/maps/documentation/overlays.html#Custom_Map_Types

=cut

use strict;
use Carp;

use File::Path;
use File::Basename;
use Getopt::Long;
use Image::Magick;

###############################################################################
# Initialization
#

# Arg variables
my ($path, $verbose, $help);

# CLI args
GetOptions(
    'path=s'  => \$path,
    'verbose' => \$verbose,
    'help'    => \$help,
);

if ($help || @ARGV < 1) {
    print STDERR "usage $0 [-v] [--path /tmp/tiles] img [, img2, img3, ...]\n";
    exit;
}

# Defaults
$path ||= '.';

###############################################################################
# Code
#

my %seen;
foreach my $img_path (@ARGV) {

    # Duplicate detection/avoidance
    next if ($seen{$img_path});
    $seen{$img_path} = 1;

    # Skip?
    unless (-e $img_path) {
        print STDERR "$img_path does not exist.\n";
        next;
    }

    # Setup
    print "Create Tiles:  $img_path\n" if ($verbose);
    my $tile_dir = "$path/" . basename($img_path);
    $tile_dir =~ s/\.\w+$//;

    # Delete any old instances of the tile directory
    rmtree($tile_dir);

    # Load the source image and a little information
    my $img = Image::Magick->new;
    $img->Read($img_path);

    my $w = $img->Get('width');
    my $h = $img->Get('height');

    # Too small to zoom?
    next unless ($h > 512 || $w > 512);

    # (Re)create the target directory
    my $ubak = umask (0);
    mkpath($tile_dir, 0, 0755);
    umask ($ubak);

    # Find the next largest multiple of 256 and the power of 2
    my $dim = ($w > $h ? $w : $h);
    my $pow = -1;
    for (;;) {
        $pow++;
        my $i = 256 * (2**$pow);
        next if ($i < $dim);
        $dim = $i;
        last;
    }

    # Resize the source image up to the larger size, so the zoomed-out images
    # get as little of the black padding/background as possible.  Hopefully it
    # won't distort the images too badly.
    if (0) {
        if ($dim > $w && $dim > $h) {

            # Determine the optimal pixel radius for sharpening, and do so
            my $sharp = (
                  $w / $dim > $h / $dim
                ? $dim / $w
                : $dim / $h
            ) / 2;
            $img->Sharpen(radius => $sharp);

            # Resize
            $img->Resize(geometry => "${dim}x$dim");
        }
    }

    # Build a new square image with a black background, and composite the
    # source image on top of it.
    my $master = Image::Magick->new;
    $master->Set('size' => "${dim}x$dim");
    $master->Read("xc:white");
    $master->Composite(
        'image'   => $img,
        'gravity' => 'Center',
    );

    # Cleanup
    undef $img;

    # Create slice layers
    my $layer = 0;
    for (;;) {

        # Google Maps only allows 19 layers (though I doubt we'll ever
        # reach this point).
        last if ($layer >= 19);

        #	    last if ($layer >= 5);
        my $width = 256 * (2**$layer);
        last if ($width > $dim);

        mkdir ("$tile_dir/$layer", 0775) unless (-d "$tile_dir/$layer");

        my $crop_master = $master->Clone();
        $crop_master->Blur(radius => ($dim / $width) / 2);
        if ($dim != $width) {
            $crop_master->Resize(
                geometry => "${width}x$width",
                blur     => .7,
            );
        }
        my $max_loop = int ($width / 256) - 1;

        if ($verbose) {
            my $num_tiles = ($max_loop + 1)**2;
            print "  Layer $layer ($num_tiles tile",
              ($num_tiles == 1 ? '' : 's'),
              ")\n";
        }

        foreach my $x (0 .. $max_loop) {
            foreach my $y (0 .. $max_loop) {
                my $crop = $crop_master->Clone();
                $crop->Crop(
                    height => 256,
                    width  => 256,
                    x      => $x * 256,
                    y      => $y * 256,
                );
                $crop->Write(
                    filename => "$tile_dir/$layer/$x-$y.jpg",
                    quality  => 75,
                );
                $ubak = umask (0);
                chmod 0644, "$tile_dir/$layer/$x-$y.jpg";
                umask ($ubak);
                undef $crop;
            }
        }
        $layer++;

        # Cleanup
        undef $crop_master;
    }

    # Cleanup
    undef $master;
}

