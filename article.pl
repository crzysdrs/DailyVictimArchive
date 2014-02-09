#!/usr/bin/perl
use strict;
use JSON;
use Lingua::EN::Titlecase::HTML;
use File::Slurp;
use Encode;

require 'gs_shared.pl';

my ($target, $index, $article, $vote) = @ARGV;
my $smallpic;
my $blurb;
my $title = "";
my $text  = read_file($article);
use Text::Iconv;
my $converter = Text::Iconv->new("cp1252", "utf8");
$text = $converter->convert($text);

my ($date_mon, $date_day, $date_year) =
  ($text =~ /<B>([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})<\/B>/is);

if (-e $vote && !-z $vote) {
    my $vote_text = read_file($vote);
    $vote_text = $converter->convert($vote_text);
    $smallpic = ($vote_text =~ /<img src="[^"]+VictimPics([^"]+)"/is)[0];
    if (length $smallpic == 0) {
        $smallpic = '/blank.gif';
    }
    if ($smallpic !~ m@^http@) {
        $smallpic = 'http://gamespy.com/dailyvictim/victimpics' . $smallpic;
    }

    $smallpic = local_img($smallpic);
    $blurb =
      ($vote_text =~ /<img src="[^"]+VictimPics\/[^"]*"[^>]+>(.+?)<\/body>/is)
      [0];
    $blurb = common_cleanup($blurb, $date_year, $date_mon, $date_day);

    $title = ($vote_text =~ /<b class="masterhead">(.+?)<\/B>/is)[0];
} else {
    $title = ($text =~ /<b class="title"><FONT SIZE=\+1>(.+?)<\/FONT>/is)[0];
}

if (length $title == 0) {
    $title = ($text =~ /<b class="title"><FONT SIZE=\+1>(.+?)<\/FONT>/is)[0];
}

$title =~ s/<BR>/ /ig;
if ($title !~ /[a-z]/) {
    my $tc = Lingua::EN::Titlecase::HTML->new($title);
    $title = $tc->title();

    #Common Needed Capitalizations
    $title =~
      s/\b(AK|C(&|&amp;)C|CS|CPU|CTF|TF|FPS|PM|PST|PVP|PC|PS2|X-?BOX|SSX|NES|SNES|MTV|WWF|WWI|WWII|CD|LAN|I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII|XIII|XIV|XV)\b/\U$1/ig;

    #S.A.T. A.K.A. E.T.
    $title =~ s/(([a-zA-Z]\.){2,})/uc($1)/ige;

    #L33T
    $title =~ s/\b(\w*[0-9]\w*)\b/\U$1/ig;
}

my $vic_pic_section =
  ($text =~ /<!-- THE VICTIM'S PIC -->(.+?)<!-- END VICTIM PIC -->/is)[0];
my $vic_pic = ($vic_pic_section =~ /<img src="(.+?)"/is)[0];
if ($vic_pic =~ m@^http@i) {

    #no modification
} elsif ($vic_pic !~ m@^/@i) {
    $vic_pic = 'http://gamespy.com/Dailyvictim/' . $vic_pic;
} else {
    $vic_pic = 'http://gamespy.com/' . $vic_pic;
}
$vic_pic = local_img($vic_pic);
my $vic_text =
  ($text =~ /<!-- VICTIM TEXT -->(.+?)<!-- END VICTIM TEXT -->/is)[0];

$vic_text = common_cleanup('<p>' . $vic_text, $date_year, $date_mon, $date_day);

$title = common_cleanup($title, $date_year, $date_mon, $date_day);

if ($index == 56) {
    my %imgs = (
        'victimpics/colorappliances.gif'   => 34,
        'victimpics/coloracjob.gif'        => 41,
        'victimpics/colormymom.gif'        => 42,
        'victimpics/colorflagdefender.gif' => 38,
        'victimpics/colorwoeisp.gif'       => 52,
        'victimpics/colorjolt.gif'         => 46,
    );

    #hack to add links for unmarked images in #56
    $vic_text =~ s@<IMG SRC="(.+?)".+?>@add_img_link(\%imgs, $1, $&)@ieg;
} elsif ($index == 34) {
    $vic_text =~ s@defending her own base@add_link(17, $&)@ie;
} elsif ($index == 38) {
    $vic_text =~ s@I am not defending our base@add_link(17, $&)@ie;
    $vic_text =~ s@like I am overclocked@add_link(34, $&)@ie;
} elsif ($index == 42) {
    $vic_text =~
      s@My mom gets more abuse on that frickin' Tribes server@add_link(21, $&)@ie;
} elsif ($index == 46) {
    $vic_text =~ s@I imagined the bats@add_link(31, $&)@ie;
} elsif ($index == 74) {
    $vic_text =~
      s@I'm not trying to say your stories about playing Baldur's Gate II aren't exciting@add_link(61, $&)@ie;
} elsif ($index == 89) {
    $vic_text =~ s@cast unsupported suspicion at you@add_link(70, $&)@ie;
} elsif ($index == 101) {
    $vic_text =~ s@Also, they suck at Tribes@add_link(93, $&)@ie;
} elsif ($index == 241) {
    $vic_text =~ s@as well as my rashes@add_link(94, $&)@ie;
} elsif ($index == 176) {
    $vic_text =~ s@this blue cord here@add_link(164, $&)@ie;
} elsif ($index == 182) {
    $vic_text =~ s@poor grammar@add_link(174, $&)@ie;
} elsif ($index == 259) {
    $vic_text =~ s/<BR>\s*<BR>\s*(They opened up into)/$1/si;
} elsif ($index == 52) {
    $vic_text =~ s/<P>(Satan! Satan lies)/$1/si;
} elsif ($index == 567) {
    $vic_text =~
      s/<A\s*title=""\s*HREF="article.php\?id=567"\s*>(.+?)<\/A>/$1/isg;
} elsif ($index == 606) {
    $vic_text =~ s@</b></a>@</a></b>@isg;
} elsif ($index == 570) {
    $blurb =~ s@while talking like a pirate@add_link(470, $&)@iseg;
} elsif ($index == 690) {
    $vic_text =~ s@(!-)->@-&gt;@ig;
} elsif ($index == 697) {
    $smallpic = 'victimpics/feb04/clipboard.gif';
} elsif ($index == 698) {
    $smallpic = 'victimpics/smallpete.gif';
} elsif ($index == 699) {
    $smallpic = 'unfinished/cowboy_s.gif';
    $blurb =
      'Why no good sir, I do not appear to be afflicted with a \"brokeback\" but if you would like to examine me regardless it will require a physical...';
}

my @conns = ($vic_text =~ /article.php\?id=([0-9]+)/ig);
push (@conns, ($blurb =~ /article.php\?id=([0-9]+)/ig));

my $sqlitedate = sqlite_date($date_year, $date_mon, $date_day);

my $c = ($vic_pic =~ /\/COLOR[^\/]+$/i) || is_color("img/$vic_pic");

if ($smallpic =~ /blank.gif/ || $smallpic eq '') {
    $smallpic = 'question-mark.gif';
}

if ($vic_pic =~ /blank.gif/) {
    $c ||= is_color("img/$smallpic");
}

print $index, " L:", $vic_pic, " S:", $smallpic, "\n";

my %article = (
    'vicpic'       => $vic_pic,
    'vicpic_small' => $smallpic,
    'text'         => polishHTML($vic_text),
    'title'        => polishHTML($title),
    'conns'        => \@conns,
    'date'         => $sqlitedate,
    'blurb'        => polishHTML($blurb),
    'id'           => $index,
    'color'        => $c,
);

foreach my $c (@conns) {
    if ($index < $c) {
        print "Forward Reference: $index -> $c\n";
    }
}

write_file($target, to_json(\%article));
