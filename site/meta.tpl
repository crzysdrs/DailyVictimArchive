{extends file='default.tpl'}
{block name="title"}
Daily Victim Archive: {$meta.title|strip_tags|escape}
{/block}
{block name="head"}
<style type="text/css">
  .inlineImageCaption {
  /*clear: all;*/
  font-size: 11px;
  font-weight: bold;
  text-align: center;
  }
  .imageInlineRight {
  margin: 0 5px 5px 5px;
  float: right;
  }
  .imageInlineCenter {
  margin: 0 auto 10px auto;
  text-align: center;
  }
  .imageInlineLeft {
  clear: both;
  float: left;
  margin-bottom: 10px;
  margin-right: 10px;
  }
</style>
<script type="text/javascript">

$(document).ready(function(){
    article_jquery();
});
</script>

{/block}
{block name="body"}
<h1>{$meta.title}</h1>
<h3>
  {$meta.author}<br />
  <span property="v:published" content="{$meta.date}">{$meta.date}</span>
</h3>
<div>
  {$meta.article}
</div>
<hr />
<p>
  <a href="./">Return To Daily Victim Archive</a>
</p>
{/block}
