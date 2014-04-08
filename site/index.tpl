{extends file="default.tpl"}
{block name="title"}
Daily Victim Archive
{/block}
{block name="head"}
{literal}
<style type="text/css">
  .Text{
  font-family: Verdana, Arial, Sans-serif, 'Times New Roman';
  font-size: 8pt;
  font-weight: normal;
  font-style: normal;
  color: #333333;
  text-decoration: none;
  }
  .myCustomClass .qtip-content{
  padding: 0px;
  }
  .num {
       text-align: right;
  }
</style>
<script type="text/javascript">
  jQuery.extend( jQuery.fn.dataTableExt.oSort, {
    "formatted-num-pre": function ( a ) {
        a = (a === "-" || a === "") ? 0 : a.replace( /[^\d\-\.]/g, "" );
        return parseFloat( a );
    },
 
    "formatted-num-asc": function ( a, b ) {
        return a - b;
    },
 
    "formatted-num-desc": function ( a, b ) {
        return b - a;
    }
  } );

  jQuery.fn.dataTableExt.aTypes.unshift(
    function ( sData )
    {
	if (sData.match(/^-?[0-9]{1,3}(,[0-9]{3})*(\.[0-9]+)?$/ig)) {
            return 'formatted-num';
	} else {
	    return null;
	}
    }
);

$(document).ready(function(){
  $('#meta_articles').dataTable(
	{
	"bPaginate":false,
	"bInfo":false,
	"bStateSave":true,
	 }
  );
  $('#dailyvictims').dataTable(
	{
	"bPaginate":false,
	"bInfo":false,
	"bStateSave":true,
        "aaSorting": [[0, "asc"]],
	}
  ).on('mouseenter', 'tr[data-vicpicsmall]', function (event) {
      var img = $(this).data('vicpicsmall');
      $(this).qtip({
          style: {classes:'qtip-light qtip-shadow myCustomClass'},
          overwrite: false,
          content: '<img style="height: 100px; width: 100px;" src="img/' + img + '"/>',
          position: {
              my: 'bottom left',
              at: 'top right',
              target: $('td', this),
              //target: 'mouse',
              viewport: $('#dailyvictims')
          },
          show: {
              event: event.type,
              ready: true,
          },
          hide: {
              fixed: true
          }	  
      }, event); 
  }); 
 });
</script>
{/literal}
{/block}

{block name="body"}
<h1> Daily Victim Archive </h1>
<h4>Just What <i>was</i> the Daily Victim?</h4>
<p>
  The Daily Victim was GameSpy's daily tribute to the millions of fine people who populated Internet culture. Every weekday a new victim was posted. The most beloved victims returned in their full-color feature and continued story each week.
</p>

<form method="get" action="http://www.google.com/search">
  <h4>Search the Daily Victim Archive</h4>
  <p>
    <input type="text" name="q" size="31" maxlength="255" value="" /> <input type="submit" value="Google Search" /> <input type="hidden" name="sitesearch" value="http://crzysdrs.sytes.net/dv/" />
  </p>
</form>

<h4>Articles About the Daily Victim</h4>

<table id="meta_articles" class="display" cellpadding="0" cellspacing="0">
  <thead><tr><th>Date</th><th>Title</th><th>Author</th></tr></thead>
  {foreach $metas as $meta}
  <tr class="Text">
    <td class="nb">{$meta.date}</td>
    <td><a href="meta.php?id={$meta.id}">{$meta.title}</a></td>
    <td>{$meta.author}</td>
  </tr>
  {/foreach}
</table>

<h4>The Daily Victims</h4>
<p>
  <ul>
    <li><a href="map.php">Google Map of Connections</a></li>
    <li><a href="reunion.php">Daily Victim Reunion</a></li>
  </ul>
</p>
<table id="dailyvictims" class="display" cellpadding="0" cellspacing="0">
  <thead><tr>
      <th>Date</th>
      <th>Score</th>
      <th>Votes</th>
      <th>Links To This</th>
      <th>Links In This</th>
      <th>Total</th>
      <th>Color</th>
      <th>Title</th>
  </tr></thead>
  {foreach $articles as $article}
  <tr class="Text" data-vicpicsmall="{$article.vicpic_small}">
    <td class="nb">{$article.date}</td>
    <td class="nb num">{$article.avg|string_format:"%.2f"}</td>
    <td class="nb num">{$article.votes|number_format:0}</td>
    <td class="nb num">{$article.inlinks}</td>
    <td class="nb num">{$article.outlinks}</td>
    <td class="nb num">{$article.total}</td>
    <td class="nb">{$article.color|yesno}</td>
    <td><a href="article.php?id={$article.id}">{$article.title}</a>
    </td>
  </tr>
  {/foreach}
</table>

<div style="font-size: 60%; float: right;">All Scores Listed From 2009-12-09</div>
<div style="font-size: 80%; clear:both;">
  Obviously all this content belongs to Gamespy and their respective authors (Dave "Fargo" Kosak, Lemuel "HotSoup" Pew, Mike "Gabriel" Krahulik). This is merely meant as a repository of the old Daily Victim, since it is no longer hosted at <a href="http://archive.gamespy.com/dailyvictim/index.asp">Gamespy</a>, it was practically a crime to let these wither and die only mirrored on the Internet Archive.
</div>
{/block}
