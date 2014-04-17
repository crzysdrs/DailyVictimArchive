use strict;
use File::Temp;
use IPC::Open2;

sub is_color($) {
    use File::Temp;
    my ($img) = @_;
    my $tmp = File::Temp->new(SUFFIX => '.png');
    my $f = $tmp->filename;
    `convert "$img" -solarize 50% -colorspace Gray "$f"`;
    my $result =
      `identify -verbose -alpha off "$f" |  sed -n '/Histogram/q; /Colormap/q; /statistics:/,\$ p'`;

    my $mean    = ($result =~ /mean: ([0-9]+\.[0-9]+)/)[0];
    my $std_dev = ($result =~ /standard deviation: ([0-9]+\.[0-9]+)/)[0];

    if ($mean == 0 || ($mean < 15 && $std_dev > $mean)) {

        #bw
        return 0;
    } else {

        #color
        return 1;
    }
}

sub add_img_link($$$) {
    my ($imgs, $img, $text) = @_;

    my $mod_img = $img;
    if ($img !~ /^img/) {
        return $text;
    }
    $mod_img =~ s/^img\///i;
    if ($imgs->{$mod_img}) {
        return
            '<a href="article.php?id='
          . $imgs->{$mod_img} . '">'
          . $text . "</a>";
    } else {
        return $text;
    }
}

sub add_link($$) {
    my ($id, $text) = @_;

    return '<a href="article.php?id=' . $id . '">' . $text . "</a>";
}

sub cleanup_stupid($) {
    my ($s) = @_;
    my $copy_s = $s;
    $s =~ s/^.*<img src="([^"]+?)\.(jpe?g|gif|png)".*$/$1big.$2/ig;
    $s =~ s@^http.*(http://.*)$@$1@ig;
    my $res = 'href="' . $s . "\">$copy_s</a>";
    return $res;
}

sub clean_ampersand($) {
    my ($follows) = @_;
    if ($follows =~ /;/) {
        return "&$follows";
    } else {
        return "&amp;$follows";
    }
}

sub common_cleanup($$$$) {
    my ($text, $date_year, $date_mon, $date_day) = @_;
    my $waybackdate =
      sprintf ("%.4d%.2d%.2d000000", $date_year, $date_mon, $date_day);

    $text =~ s@<br clear="all"/?>@<br>@ig;
    $text =~ s@<rb>@<br>@ig;
    $text =~ s@<br/?([^><]*)>?@<br>$1@isg
      ;    #notably for 586, 629. Found some "hidden" text.
    $text =~ s@^(\s+|<br>)*@@is;
    $text =~ s@herf=@href=@ig;

    $text =~ s@href="[^"]+?img_[0-9]+.html">(.+?)</a>@cleanup_stupid($1)@isge;
    $text =~ s@href="(%20| )+@href="@ig;
    $text =~
      s@href=("?)[^"]*index.asp(?:\?|%3F)id=([0-9]+)(?:(?:-[0-9]+)?.html(?:[0-9]+)?)?\1@" href=\"article.php?id=$2\" "@eig;
    $text =~
      s@(href|src)="([^"]+\.(?:gif|jpg|jpeg|png))"@$1 .'="img/' . local_img($2) . '"'@ieg;
    $text =~ s@href="http://web.archive.org/web/[0-9]{14}/@href="@ig;
    $text =~ s@href="/@href="http://gamespy.com/@ig;

    #THIS IS OPTIONAL
    $text =~
      s@href="(http://[^"]+)\.(com|net|org|edu)"@'href="' . lc($1) . '.' . $2 . '/"'@ige;

    $text =~
      s@href="http://@href="http://web.archive.org/web/$waybackdate/http://@ig;
    $text =~ s@href="http://[^"]*/dailyvictim/?"@href="./"@ig;
    $text =~ s@archive.gamespy.com@gamespy.com@ig;
    $text =~ s@target="_blank"@@ig;
    $text =~ s@target="_?new"@@ig;
    $text =~ s@BORDER="?0"?@@ig;
    $text =~ s@<(/?)strike>@<$1del>@ig;
    $text =~ s/\x{C2}\x{A0}/&nbsp;/ig;

    #$text =~ s@\x{FFFD}@&nbsp;@ig;

    return $text;
}

sub font_size($) {
    my ($font) = @_;
    return $font * 10 + 100;
}

sub polishHTML($) {
    my ($text) = @_;
    my ($tidy_in, $tidy_out);
    my $pid = open2($tidy_out, $tidy_in,
        "tidy -asxhtml -wrap 9999999999 --alt-text \"\" --indent yes -utf8 2> /dev/null"
    );
    $text =~ s/<br( *\/)?>((\s|&nbsp;)*<br( *\/)?>)+/<p>/isg;
    $text =~ s/\n+/\n/isg;
    $text =~
      s/align="?(left|right|center)"?/style="float:\L$1; text-align:\L$1;"/ig;
    $text =~ s/float:center;//ig;

    print $tidy_in $text;
    close $tidy_in;

    $text = join ("", <$tidy_out>);

    $text =~ s/^.*<body>(.+?)<\/body>.*$/$1/is;
    $text =~ s@<i>(.+?)</i>@<em>$1</em>@igs;
    $text =~ s@<b>(.+?)</b>@<strong>$1</strong>@igs;
    $text =~
      s@<center>(.+?)</center>@<div style="text-align: center;">$1</div>@isg;
    $text =~
      s@<font s[io]ze="(.+?)">@'<span style="font-size:' . font_size($1) . '%;">'@iesg;
    $text =~ s@<font color="(.+?)">@<span style="color: $1;">@ig;
    $text =~ s@</font>@</span>@isg;
    $text =~ s@<u>@<span class="uline">@ig;
    $text =~ s@</u>@</span>@ig;
    $text =~ s@^(\s+|<br />)*@@isg;
    $text =~ s@(\s+|<br />)*$@@isg;

    #$text =~ s@<p>(\s|&nbsp;|<br />)*</p>@@igs;
    return $text;
}

sub roundoff {
    my $num = shift;
    my $roundto = shift || 1;

    return int ($num / $roundto + 0.5) * $roundto;
}

sub sqlite_date_full($$$$$$) {
    my ($date_year, $date_mon, $date_day, $hr, $min, $sec) = @_;
    return sprintf ("%.4d-%.2d-%.2d %.2d:%.2d:%.2d",
        $date_year, $date_mon, $date_day, $hr, $min, $sec);
}

sub sqlite_date($$$) {
    my ($date_year, $date_mon, $date_day) = @_;
    return sprintf ("%.4d-%.2d-%.2d", $date_year, $date_mon, $date_day);
}

sub local_img($) {
    my ($img) = @_;
    my ($img_path, $img_name) = local_img_parts($img);
    return $img_path . $img_name;
}

sub local_img_parts($) {
    my ($img) = @_;
    my ($img_path, $img_name);
    $img =~ s@[^/]+/\.\./@@;
    $img =~ s@-[0-9]+\.(gif|png|jpe?g)$@.$1@;

    if ($img =~ m@^http://web.archive.org/@) {
        ($img_path, $img_name) = ($img =~
              m@^http://web.archive.org/web/[^/]+/http://[^/]+/(.+?)([^/]*$)@i);
    } elsif ($img =~ /^http/) {
        ($img_path, $img_name) = ($img =~ m@^http://[^/]+/(.+?)([^/]*$)@i);
    } else {
        ($img_path, $img_name) = ($img =~ m@^(.+?)([^/]*$)@i);
    }

    $img_path = lc ($img_path);
    $img_name = lc ($img_name);
    $img_path =~ s@^/dailyvictim/@@ig;
    $img_path =~ s@^(\.\.)?/(dailyvictim/)+@@ig;
    $img_path =~ s@^(?:comics/)?/?dailyvictim/(.+?|)$@$1@i;
    $img_path =~ s@^.+?image\.asp\?/(?:dailyvictim)?@/@ig;
    $img_path =~ s@/+@/@ig;

    return ($img_path, $img_name);
}

1;
