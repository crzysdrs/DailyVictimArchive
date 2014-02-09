<?php
/**
* Article Page
*
* PHP version 5
*
* @category Site
* @package  N/A
* @author   Mitch Souders <crzysdrs@gmail.com>
* @license  http://www.gnu.org/copyleft/gpl.html GNU General Public License
* @link     http://crzysdrs.sytes.net
*/
require_once '/usr/share/php/smarty3/Smarty.class.php';
$smarty = new Smarty;
$db = new Sqlite3("dv.db");
$stmt = $db->prepare(
    "SELECT article.id as id, title, article, vicpic,
            date, vicpic_small, blurb, avg, votes
     FROM article 
     JOIN stats on article.id = stats.id    
     WHERE article.id=:id"
);

$stmt->bindValue(':id', $_GET['id']);
$q = $stmt->execute();

$article = $q->fetchArray();
$smarty->assign('article', $article);
$smarty->assign(
    'vicpic_path',
    "http://" . $_SERVER['SERVER_NAME'] . "/dv/img/" . $article['vicpic']
);
$smarty->assign(
    'url', 
    "http://" . $_SERVER['SERVER_NAME'] 
    . $_SERVER['PHP_SELF'] . "?id=" . $article['id']
);
$smarty->assign('map_file', "./dags/" . $article['id'] . ".map");

$next_q = $db->query(
    "SELECT title, id, vicpic_small
     FROM article WHERE
     (julianday(date) - julianday('" . $article['date'] . "')) > 0
     ORDER BY date ASC LIMIT 1;"
);

if ($row = $next_q->fetchArray()) {
    $next = [
        'id'=>$row['id'],
        'vicpic_small'=>$row['vicpic_small'],
        'title'=>$row['title']
    ];
    $smarty->assign('next_button', $next);
}

$prev_q = $db->query(
    "SELECT title, id, vicpic_small
     FROM article
     WHERE (julianday(date) - julianday('" . $article['date'] . "')) < 0
     ORDER BY date DESC LIMIT 1;"
);

if ($row = $prev_q->fetchArray()) {
    $prev = [
        'id'=>$row['id'],
        'vicpic_small'=>$row['vicpic_small'],
        'title'=>$row['title']
    ];
    $smarty->assign('prev_button', $prev);
}

$stmt = $db->prepare(
    "SELECT title, article.id, article.vicpic_small 
     FROM conns 
     JOIN article on conns.dst = article.id
     WHERE conns.src=:id"
);

$stmt->bindValue(':id', $article['id']);
$q = $stmt->execute();

if ($q->fetchArray()) {
    $q->reset();
    $outlinks = array();
    while ($row = $q->fetchArray()) {
        $outlinks[] = [
            'id'=>$row['id'], 
            'vicpic_small'=>$row['vicpic_small'],
            'title'=>$row['title']];
    }
    $smarty->assign('outlinks', $outlinks);
}

$stmt = $db->prepare(
    "SELECT title, article.id, article.vicpic_small
     FROM conns
     JOIN article on conns.src = article.id
     WHERE conns.dst=:id"
);
$stmt->bindValue(':id', $article['id']);
$q = $stmt->execute();

if ($q->fetchArray()) {
    $q->reset();
    $inlinks = array();
    while ($row = $q->fetchArray()) {
        $inlinks[] = [
            'id'=>$row['id'],
            'vicpic_small'=>$row['vicpic_small'],
            'title'=>$row['title']
        ];
    }
    $smarty->assign('inlinks', $inlinks);
}

$smarty->assign(
    'breadcrumbs', 
    array(
        array('url'=>'/', 'title'=>'CrzySdrs'),
        array('url'=>'/dv/', 'title'=>'Daily Victim Archive'),
        array('url'=>'#', 'title'=>$article['title'])
    )
);

$smarty->display('article.tpl');

?>
