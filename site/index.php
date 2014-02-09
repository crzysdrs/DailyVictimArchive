<?php
/**
* Main Index
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

/**
* Smarty Function to Convert 0,1 to Yes,No
*
* @param string $string A string of 0 or 1
*
* @return Yes/No
*/
function yesno($string) 
{
    return $string == '0' ? 'No' : 'Yes';
}

$smarty = new Smarty;
$smarty->registerPlugin("function", 'yesno', 'yesno');

$db = new PDO('sqlite:dv.db');

$q = $db->query("SELECT id, title, author, date FROM meta_article ORDER BY date");
$smarty->assign('metas', $q);

$q = $db->query(
    "SELECT article.id, title, avg, votes, date,
        inlinks, outlinks, inlinks + outlinks as total,
        vicpic_small, winner, color
     FROM article 
     LEFT JOIN stats on stats.id = article.id
     ORDER BY article.date"
);

$smarty->assign('articles', $q);
$smarty->assign(
    'breadcrumbs', 
    array(
        array('url'=>'/', 'title'=>'CrzySdrs'),
        array('url'=>'/dv/', 'title'=>'Daily Victim Archive')
    )
);

$smarty->display('index.tpl');

?>
