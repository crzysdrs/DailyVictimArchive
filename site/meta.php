<?php
/**
* Meta Articles
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
    "SELECT title, article, date, author FROM meta_article WHERE id=:id"
);
$stmt->bindValue(':id', $_GET['id']);
$q = $stmt->execute();
$meta = $q->fetchArray();

$smarty->assign('meta', $meta);
$smarty->assign(
    'breadcrumbs', 
    array(
        array('url'=>'/', 'title'=>'CrzySdrs'),
        array('url'=>'/dv/', 'title'=>'Daily Victim Archive'),
        array('url'=>'#', 'title'=>$meta['title'])
    )
);

$smarty->display('meta.tpl');
?>
