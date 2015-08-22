#!/usr/bin/perl
use strict;

use DBI;
use utf8;
use encoding 'UTF-8';
use Lingua::EN::Titlecase::HTML;
use IPC::Open2;
use JSON;
use File::Slurp;

require 'gs_shared.pl';

my ($dbfile, $tmpdir, $mirrordir) = @ARGV;
`rm $dbfile`;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

$dbh->do("begin transaction;");
$dbh->do(
    "CREATE TABLE article(id INTEGER PRIMARY KEY ASC, date TEXT, title TEXT, vicpic TEXT, vicpic_small TEXT, article TEXT, blurb TEXT, winner INTEGER, color INTEGER, user_submitted TEXT)"
);
$dbh->do(
    "CREATE TABLE votes(id INTEGER PRIMARY KEY ASC, article_id INTEGER, date TEXT, score INTEGER, count INTEGER, UNIQUE(article_id, date, score) ON CONFLICT IGNORE);"
);

#"YYYY-MM-DD HH:MM:SS.SSS"
$dbh->do(
    "CREATE TABLE conns(id INTEGER PRIMARY KEY ASC, src INTEGER, dst INTEGER, 
UNIQUE(src, dst) ON CONFLICT IGNORE);"
);

$dbh->do(
    "CREATE TABLE meta_article(id INTEGER PRIMARY KEY ASC, date TEXT, title TEXT, article TEXT, author TEXT);"
);

$dbh->do(
    "CREATE TABLE strings(id INTEGER PRIMARY KEY ASC, str TEXT, UNIQUE(str) ON CONFLICT IGNORE);"
);
$dbh->do(
    "CREATE TABLE keywords (id INTEGER PRIMARY KEY ASC, article_id INTEGER, str_id INTEGER, UNIQUE(article_id, str_id) ON CONFLICT IGNORE);"
);
$dbh->do(
    "CREATE TABLE concepts (id INTEGER PRIMARY KEY ASC, article_id INTEGER, str_id INTEGER, UNIQUE(article_id, str_id) ON CONFLICT IGNORE);"
);

my $article = $dbh->prepare(
    "INSERT INTO article (id, date, title, article, vicpic, vicpic_small, blurb, winner, color, user_submitted) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, '');"
);
my $conns     = $dbh->prepare("INSERT INTO conns (src, dst) VALUES (?, ?) ");
my $get_title = $dbh->prepare("SELECT title from article WHERE id=?");
my $votes     = $dbh->prepare(
    "INSERT INTO votes (article_id, date, score, count) VALUES (?, ?, ?, ?)");
my $meta = $dbh->prepare(
    "INSERT INTO meta_article (title, date, article, author) VALUES (?, ?, ?, ?)"
);

foreach my $j (`ls ${tmpdir}/*.article`) {
    chomp $j;
    my $text = read_file($j);
    my $json = from_json($text);
    $article->execute($json->{id}, $json->{date}, $json->{title}, $json->{text},
        $json->{vicpic}, $json->{vicpic_small}, $json->{blurb}, $json->{color});

    foreach my $c (@{$json->{conns}}) {
        if ($json->{id} < $c) {
            print "Forward Reference: $json->{id} -> $c\n";
        }

        if ($json->{id} != $c) {
            $conns->execute($json->{id}, $c);
        }
    }
}

foreach my $j (`ls ${tmpdir}/*.vote`) {
    chomp $j;
    my $json = from_json(read_file($j, {binmode => ':utf8'}));
    foreach my $d (keys %{$json->{'votes'}}) {
        foreach my $v (keys %{$json->{'votes'}->{$d}}) {
            $votes->execute($json->{'id'}, $d, $v,
                $json->{'votes'}->{$d}->{$v});
        }
    }
}

sub get_article_text($) {
    my ($text) = @_;
    if ($text =~ m/<div class="article-body">(.+?)<!-- START: ads column -->/si)
    {
        $text = $1;
        $text =~ s/<!-- START: paging -->(.+?)<!-- END: paging -->//sgi;
        $text =~
          s/<!-- START: Latest Articles -->(.+?)<!-- END: Latest Articles -->//sgi;
        $text =~ s@^(.+?)Next:</A>(.+?)$@@mig;
        return $text;
    }
}

sub get_editor_info($$) {
    my ($text, $info) = @_;

    if ($text =~ /<!-- START: editor info -->(.+?)<!-- END: editor info -->/is)
    {
        my $author =
          ($1 =~
              m@<a href="http://www.gamespy.com/contact-us.html">(.+?)</a>@is)
          [0];
        my ($mon, $day, $year) = ($1 =~
              m@<span class="row-date">([a-z]+) ([0-9]+), ([0-9]+)</span>@is);
        $info->{author} = $author;
        $info->{day}    = $day;
        $info->{year}   = $year;
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sept Oct Nov Dec);
        my $index  = 0;
        foreach my $m (@months) {
            $index++;
            if ($mon =~ /$m/i) {
                $info->{month} = $index;
            }
        }
        if (!defined $info->{month}) {
            print "MISSING MONTH DATA\n";
        }
    }
}

#handle meta articles
my $folder       = "${mirrordir}/";
my @anat         = `ls $folder/anat*`;
my $anat_article = "";
my %editor;
foreach my $a (@anat) {
    chomp $a;
    print "Reading $a\n";
    my $text = read_file($a, {binmode => ':utf8'});
    get_editor_info($text, \%editor);
    $anat_article .= get_article_text($text);
}
$editor{author} = "Dave 'Fargo' Kosak and Mike 'Gabriel' Krahulik";
$anat_article =
  common_cleanup($anat_article, $editor{year}, $editor{month}, $editor{day});
$anat_article =~
  s@<div class="inlineImageCaption".+?width:(.+?);.+?>(.+?)</div>@<br /><span class="inlineImageCaption" style="display:inline-block; width:$1;">$2</span>@isg;
$anat_article =~ s@<img(.+?)style="[^"]+?"([^>]+?)>@<img $1 $2/>@img;
$meta->execute(
    "Anatomy of A Daily Victim",
    sqlite_date($editor{year}, $editor{month}, $editor{day}),
    polishHTML($anat_article),
    $editor{author}
);

my $text = read_file("$folder/farewell.html", {binmode => ':utf8'});
my $farewell = common_cleanup($text, 2009, 2, 6);

$meta->execute(
    "Excerpt From Fargo Fond Farewell",
    sqlite_date(2009, 2, 6),
    polishHTML($farewell), "Dave 'Fargo' Kosak"
);

my @top10         = `ls $folder/top10.*`;
my $top10_article = "";
my %editor;
foreach my $a (@top10) {
    chomp $a;
    print "Reading $a\n";
    my $text = read_file($a, {binmode => ':utf8'});
    get_editor_info($text, \%editor);

    if ($text =~ /<!-- LATEST TOP10 -->(.+?)<!-- END LATEST TOP10 -->/is) {
        $text = $1;
    }
    $text =~ s@^.*Next:</a>.*$@@igm;
    $text =~ s@^.*next\.gif.*$@@igm;
    $text =~ s@^.*prev\.gif.*$@@igm;
    $text =~ s@<b class="title">Top 10 Daily Victims</b>.+?<br><br>@@isg;

    $top10_article .= $text;
}
$editor{year}   = 2001;
$editor{month}  = 7;
$editor{day}    = 30;                     #?????
$editor{author} = "Dave 'Fargo' Kosak";

$top10_article =
  common_cleanup($top10_article, $editor{year}, $editor{month}, $editor{day});
$top10_article =~ s@<table[^>]+?>|</table>@@ig;
$top10_article =~ s@<tr>|</tr>@@ig;
$top10_article =~ s@<!--.+?-->@@ig;
$top10_article =~ s@<td[^>]+?>(.+?)</td>@<div align="center">$1</div>@isg;
$top10_article =~ s@align="center"@align="right"@i;

$meta->execute(
    "Top 10 Daily Victims",
    sqlite_date($editor{year}, $editor{month}, $editor{day}),
    polishHTML($top10_article),
    $editor{author}
);

my $artist_file = $folder . 'artist.html';
my $artist_text = read_file($artist_file, {binmod => ':utf8'});
my %editor;
get_editor_info($artist_text, \%editor);
$editor{author} = "Gamespy Staff";
$artist_text = common_cleanup(get_article_text($artist_text),
    $editor{year}, $editor{month}, $editor{day});
$meta->execute(
    "The Artist and the Madman",
    sqlite_date($editor{year}, $editor{month}, $editor{day}),
    polishHTML($artist_text),
    $editor{author}
);

my %editor;
my $who_file = $folder . 'who.html';
my $who_text = read_file($who_file, {binmode => ':utf8'});
if ($who_text =~ m@<b class="title">(?:.+?)</b>(.+?)<P><CENTER>Now read@si) {
    $who_text = $1;
} else {
    print "Didn't find WHO text.\n";
}
$editor{author} =
  "Dave 'Fargo' Kosak, Mike 'Gabriel' Krahulik, Lemuel 'HotSoup' Pew";
$editor{year}  = 2000;
$editor{month} = 10;
$editor{day}   = 2;

$who_text =
  common_cleanup($who_text, $editor{year}, $editor{month}, $editor{day});
$who_text =~ s@<A HREF="(?:.+?)how.shtm">(.+?)</a>@$1@ig;
$who_text =~
  s@<img src="(?:.+?)line.gif"(.+?)>@<hr style="display:block; clear:both;">@ig;
$meta->execute(
    "Who Makes This Thing?",
    sqlite_date($editor{year}, $editor{month}, $editor{day}),
    polishHTML($who_text), $editor{author}
);

sub who($$$$$$) {
    my ($file, $author, $year, $month, $day, $meta) = @_;
    my %editor;
    my $who_text = read_file($file, {binmode => ':utf8'});
    if ($who_text =~
        m@<b class="title">(?:.+?)</b>(.+?)<img src="(?:.+?)line.gif"@si) {
        $who_text = $1;
    } else {
        print "Didn't find HOW $file text.\n";
    }
    $editor{author} = $author;
    $editor{year}   = $year;
    $editor{month}  = $month;
    $editor{day}    = $day;
    $who_text =
      common_cleanup($who_text, $editor{year}, $editor{month}, $editor{day});
    $meta->execute(
        "How Does it Work?",
        sqlite_date($editor{year}, $editor{month}, $editor{day}),
        polishHTML($who_text), $editor{author}
    );
}

who(
    $folder . 'how_hotsoup.html',
    "Dave 'Fargo' Kosak and Lemuel 'HotSoup' Pew",
    2002, 3, 1, $meta
);
who(
    $folder . 'how_gabe.html',
    "Dave 'Fargo' Kosak and Mike 'Gabriel' Krahulik",
    2000, 10, 2, $meta
);

$dbh->do(<<END);
CREATE VIEW stats as 
SELECT article.id, ifnull(avg, 0) as avg, ifnull(votes, 0) as votes,
	     ifnull(inlinks, 0) as inlinks, ifnull(outlinks, 0) as outlinks FROM article 
LEFT JOIN (SELECT (sum(count * score) * 1.0) / sum(count) as avg, sum(count) as votes, article_id FROM votes where date='2009-12-09 15:45:37' GROUP BY article_id) as avg_table on avg_table.article_id = article.id
LEFT JOIN (SELECT count(id) as inlinks, dst from conns GROUP BY dst) 
	     as ins on ins.dst = article.id
LEFT JOIN (SELECT count(id) as outlinks, src from conns GROUP BY src)
	     as outs on outs.src = article.id
END

$dbh->do("commit;");

my $all =
  $dbh->prepare("SELECT id, article, vicpic_small, vicpic FROM article");
$all->execute();
my $missing = 0;
my $total   = 0;
my $archivedir = "_build/archive/";
    
sub check_imgs($$$$) {
    my ($id, $t, $missing, $total) = @_;
    while ($t =~ m@(?:src|href)="([^"]+\.(?:jpe?g|png|gif))"@ig) {
        if (!-e $archivedir . $1) {
            print $id, ": ", $1 . " missing.\n";
            $$missing++;
        }
        $$total++;
    }
}

while (my $all_row = $all->fetchrow_hashref()) {
    check_imgs('A' . $all_row->{id}, $all_row->{article}, \$missing, \$total);

    if (!-e $archivedir . "img/" . $all_row->{vicpic_small}) {
        print $all_row->{vicpic_small} . " missing.\n";
        $missing++;
    }
    $total++;
    if (!-e $archivedir . "img/" . $all_row->{vicpic}) {
        print $all_row->{vicpic} . " missing.\n";
        $missing++;
    }
    $total++;
}
my $meta = $dbh->prepare("SELECT id, article from meta_article");
$meta->execute();
while (my $meta_row = $meta->fetchrow_hashref()) {
    check_imgs("M" . $meta->{id}, $meta_row->{article}, \$missing, \$total);
}
print "Missing $missing/$total images.\n";

$dbh->disconnect();

if ($missing > 0) {
    `rm '$dbfile'`;
    exit 1;
}
