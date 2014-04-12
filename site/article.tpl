{extends file='default.tpl'}
{block name="head"}
  <!-- Facebook Specific Properties -->
  <meta property="og:title" content="{$article.title|strip_tags|escape}" /> 
  <meta property="og:description" content="Daily Victim Archive For {$article.date|escape}" />  
  <meta property="og:image" content="{$vicpic_path|strip_tags|escape}" /> 
  <meta property="og:url" content="{$url|escape}" /> 
  <!-- End Facebook Specific Properties -->
{/block}
{block name="javascript"}
  <script type="text/javascript">
    $(document).ready(function() {
    article_jquery();
    });
  </script>
{/block}
{block name="title"}
Daily Victim Archive: {$article.title|strip_tags}
{/block}
{block name="body"}
  <div xmlns:v="http://rdf.data-vocabulary.org/#" typeof="v:Review-aggregate"> 
    <h1>{$article.title}</h1>
    <h3>
      <span property="v:published" content="{$article.date}">{$article.date}</span>
    </h3>
    
    <!-- AddThis Button BEGIN -->
    <div class="addthis_toolbox addthis_default_style ">
      <a class="addthis_button_preferred_1"></a>
      <a class="addthis_button_preferred_2"></a>
      <a class="addthis_button_preferred_3"></a>
      <a class="addthis_button_compact"></a>
      <a class="addthis_counter addthis_bubble_style"></a>
    </div>

    <script type="text/javascript">var addthis_config = { "data_track_addressbar":true } ;</script>
    <script type="text/javascript" src="http://s7.addthis.com/js/300/addthis_widget.js#pubid=ra-50875e9b31b623b4"></script>
    <!-- AddThis Button END -->
    
    <img style="float: right;" src="img/{$article.vicpic}" alt="Victim Pic Large" />
    
    <div id="articleBody">
      {$article.article}
    </div>
    <div id="articleBlurb">
      <img style="float:left; padding-right: 5px; height:100px; width:100px;" src="img/{$article.vicpic_small}" alt="Victim Pic Small" />
      {$article.blurb}
    </div>
    <hr />
    <div style="overflow: auto; clear: both;">
      <div style="width: 33%; float:left; text-align:left;">
	{if isset($prev_button) }
	<a rel="prev" href="article.php?id={$prev_button.id}" title="{$prev_button.title|escape}">
	  <img style="border-style:none;" src="img/images/sub_layout/prev.gif" alt="Prev Button"/><br />
	  <img style="border-style:none; float:left; height:100px; width:100px;" src="img/{$prev_button.vicpic_small}" />
	  {$prev_button.title}
	</a>
	{else}
	&nbsp;
	{/if}
      </div>
      <div style="width: 33%; float:left; text-align: center;">
	<a href="index.php">Back to Index</a>
      </div>
      <div style="width: 33%; float:left; text-align:right;">
	{if isset($next_button)}
	<a rel="next" href="article.php?id={$next_button.id}" title="{$next_button.title|escape}">
	  <img style="border-style:none;" src="img/images/sub_layout/next.gif" alt="Next Button"/><br />
	  <img style="border-style:none; float:right; height:100px;width:100px;" src="img/{$next_button.vicpic_small}" />
	  {$next_button.title}
	</a>
	{else}
	&nbsp;
	{/if}
      </div>
    </div>
    <hr />
    {if isset($inlinks)}
    <h3>Links to this Daily Victim:</h3>
    <ul>
      {foreach $inlinks as $in}      
      <li style="list-style:none;">
	<img style="vertical-align: middle" height="25" width="25"
	     src="img/{$in.vicpic_small}" alt="{$in.title|strip_tags|escape}" />
	<a href="article.php?id={$in.id}" title="{$in.title|strip_tags|escape}">{$in.title}</a>
      </li>
      {/foreach}
    </ul>
    {/if}

    {if isset($outlinks)}
    <h3>Links in this Daily Victim:</h3>
    <ul>
      {foreach $outlinks as $out}      
      <li style="list-style:none;">
	<img style="vertical-align: middle" height="25" width="25"
	     src="img/{$out.vicpic_small}" alt="{$out.title|strip_tags|escape}" />
	<a href="article.php?id={$out.id}" title="{$out.title|strip_tags|escape}">{$out.title}</a>
      </li>
      {/foreach}
    </ul>
    {/if}

    {if $article.votes > 0}
    <h5>
      <span rel="v:rating">
	<span typeof="v:Rating">
	  Average Score: <span property="v:average">{$article.avg|string_format:"%.2f"}</span>; 
          <span property="v:best" content="10"/>  
          <span property="v:worst" content="1"/> 
	</span>
      </span> 
      Total Votes: <span property="v:votes">{$article.votes}</span> as of 2009-12-09.
    </h5>
    <img src="chart/{$article.id}.png" alt="Histogram of Votes"/> <br />
    <img src="chart/{$article.id}_history.png" alt="Plot of Scores/Votes Change over Time"/>
    {else}
    <h5> No vote data for this article. </h5>
    {/if}

    <h3>Two Hops From This Article</h3> 
    <a href="map.php?id={$article.id}">View In Map</a>
    <div>
      {if !isset($inlinks) && !isset($outlinks)}
      No articles connected to this one.
      {else}
      <img src="dags/{$article.id}.png" usemap="#G" alt="Two Hops"/> 
      {include file=$map_file}
      {/if}
    </div>
  </div>
{/block}
