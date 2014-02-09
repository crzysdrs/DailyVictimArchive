<?php
/**
* JSON Article
*
* PHP version 5
*
* @category Site
* @package  N/A
* @author   Mitch Souders <crzysdrs@gmail.com>
* @license  http://www.gnu.org/copyleft/gpl.html GNU General Public License
* @link     http://crzysdrs.sytes.net
*/

$db = new SQLite3("dv.db");

$ids = [];
if (!isset($_GET['id'])) {
    header('HTTP/1.1 400 Bad Request');
    exit (0);
} else if (is_array($_GET['id'])) {
    $ids = $_GET['id'];
} else {
    $ids = array($_GET['id']);
}
header('Content-Type:text/javascript; charset=UTF-8');
$result = array();

foreach ($ids as $id) {
    $stmt = $db->prepare(
        "SELECT article.id, title, date, vicpic_small,
            avg, votes, inlinks, outlinks 
         FROM article
         LEFT JOIN stats on stats.id = article.id WHERE article.id=:id"
    );
    $stmt->bindValue(':id', $id);
    $q = $stmt->execute();
    if ($row = $q->fetchArray()) {
        $result[$id] = $row;
    }
}
echo json_encode($result);
?>
