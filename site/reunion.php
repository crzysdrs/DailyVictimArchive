<?php
/**
* Reunion
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

$smarty->assign('tile_loc', 'tiles/');
$smarty->assign('tile_name', 'reunion');
$smarty->assign('max_zoom', 5);

$smarty->display('reunion.tpl');
?>
