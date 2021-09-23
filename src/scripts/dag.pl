#!/usr/bin/perl
use strict;
use DBI;
use Cwd;

sub strip_html($) {
    my ($str) = @_;
    $str =~ s/<.+?>//ig;
    $str =~ s/&/&amp;/ig;
    $str =~ s/"/&quot;/ig;
    return $str;
}

sub sort_unique {
    my %hash;
    @hash{@_} = ();
    return sort keys %hash;
}

my ($id, $dagdir, $dbfile)  = @ARGV;

my $dbh = DBI->connect("dbi:SQLite:dbname=${dbfile}", "", "");

my $trans_forward = $dbh->prepare("SELECT src, dst from conns WHERE src = ?");
my $trans_back    = $dbh->prepare("SELECT src, dst from conns WHERE dst = ?");

sub trans_clos_forward($$) {
    my ($id, $depth) = @_;
    my @result = ($id);
    if ($depth == 0) {
        return @result;
    }
    my @forward = ();
    $trans_forward->execute($id);
    while (my $row = $trans_forward->fetchrow_hashref) {
        if ($row->{dst} != $id) {
            push @forward, $row->{dst};
        }
    }
    @forward = sort_unique(@forward);

    foreach my $i (@forward) {
        push @result, trans_clos_forward($i, $depth - 1);
    }
    return @result;
}

sub trans_clos_back($$) {
    my ($id, $depth) = @_;
    my @result = ($id);
    if ($depth == 0) {
        return @result;
    }
    my @back = ();
    $trans_back->execute($id);
    while (my $row = $trans_back->fetchrow_hashref) {
        if ($row->{src} != $id) {
            push @back, $row->{src};
        }
    }
    @back = sort_unique(@back);

    foreach my $i (@back) {
        push @result, trans_clos_back($i, $depth - 1);
    }
    return @result;
}

sub trans_clos($$) {
    my ($id, $depth) = @_;
    my @result;
    push @result, trans_clos_forward($id, $depth);
    push @result, trans_clos_back($id, $depth);
    return @result;
}

my $node = $dbh->prepare(
    "SELECT id, article.vicpic_small, article.title FROM article WHERE id = ?");

sub format_node($$$$$) {
    my ($id, $title, $label, $img,$attribs) = @_;
    return
        $id
      . " [${label}nodesep=0.75,URL=\"article.php?id=${id}\",shape=square,label=\"\",tooltip=\""
      . strip_html($title)
      . "\",image=\""
      . cwd() . '/'
      . $img
      . "\",$attribs];\n";
}


if ($id ne 'all') {
    print "Creating DAG for $id\n";
    use utf8;
#    open my $pipe, ">-";
    open my $pipe,
      "| dot -Tcmapx -o ${dagdir}/$id.map -Tpng -o ${dagdir}/$id.png -Tplain -o ${dagdir}/$id.plain"
      or die ("Unable to open pipe");

    print $pipe "digraph G {\n";
    print $pipe "graph[size=\"7.75,10.25\"];\n";
    my @ids = sort_unique(trans_clos($id, 2));
    my $list = join (', ', @ids);
    my $conns = $dbh->prepare(
        "SELECT src, dst FROM conns WHERE src IN ($list) and dst IN ($list)");
    $conns->execute();
    while (my $row = $conns->fetchrow_hashref) {
        print $pipe "$row->{dst} -> $row->{src};\n";
    }
    my @uniques = @ids;
    foreach my $u (@uniques) {
        $node->execute($u);
        while (my $row = $node->fetchrow_hashref) {
            my $label = "";
            if ($row->{id} == $id) {
                $label = "color=red,";
            }
            my $img = "static/img/$row->{vicpic_small}";
            my $fmt = format_node($row->{id}, $row->{title}, $label, $img, '');
            print $pipe $fmt;
        }
    }
    print $pipe "}\n";
    close $pipe;
} elsif ($id == 'all') {
    print "Creating DAG for ALL\n";

    my $all_png   = $dagdir . "/all.png";
    my $all_plain = $dagdir . "/all.plain";
    my $all_map   = $dagdir . "/all.map";
    my $all_svg   = $dagdir . "/all.svg";
    
    open my $pipe,
      "| ccomps -x -z | dot | gvpack -g | sed -e 's/label=\"[^\"]*\",\\?//ig' | neato -Nlabel= -s -y -n2 -Tpng -o $all_png -Tplain -o $all_plain -Tcmapx -o $all_map -Tsvg -o $all_svg";

    binmode ($pipe, ":utf8");

    print $pipe "digraph G {\n";

    my $all = $dbh->prepare("SELECT id, title, vicpic_small FROM article");

    $all->execute();
    
    while (my $allrow = $all->fetchrow_hashref) {
        print $pipe format_node($allrow->{id}, $allrow->{title}, "",
                                'static/img/' . $allrow->{vicpic_small}, '');
    }

    my $all_conns = $dbh->prepare("SELECT src, dst from conns");
    $all_conns->execute();
    while (my $c = $all_conns->fetchrow_hashref) {
        print $pipe $c->{dst} . " -> " . $c->{src} . ";\n";
    }
    print $pipe "}\n";
    close $pipe;
}
