<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN"
    "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    version="XHTML+RDFa 1.0" xml:lang="en">
<head>
  <meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
  <link href="main.css" rel="stylesheet" type="text/css" />
  <title>{block name="title"}Default Title{/block}</title>
  <!-- JQuery Begin -->
  <script type="text/javascript" src="http://code.jquery.com/jquery-1.8.3.js"></script>
  <script type="text/javascript" src="http://qtip2.com/v/stable/jquery.qtip.js"></script> 
  <link rel="stylesheet" type="text/css" href="http://qtip2.com/v/stable/jquery.qtip.css"/>
  <link rel="stylesheet" type="text/css" href="//cdnjs.cloudflare.com/ajax/libs/datatables/1.9.4/css/jquery.dataTables.css"/>
  <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/datatables/1.9.4/jquery.dataTables.min.js"></script>
  
  <!-- Fancy Box -->
  <link type="text/css" rel="stylesheet" href="//cdn.jsdelivr.net/fancybox/2.1.5/helpers/jquery.fancybox-buttons.css" />
  <script type="text/javascript" src="//cdn.jsdelivr.net/fancybox/2.1.5/helpers/jquery.fancybox-buttons.js"></script>
  <script type="text/javascript" src="//cdn.jsdelivr.net/fancybox/2.1.5/helpers/jquery.fancybox-media.js"></script>
  <link type="text/css" rel="stylesheet" href="//cdn.jsdelivr.net/fancybox/2.1.5/helpers/jquery.fancybox-thumbs.css" />
  <script type="text/javascript" src="//cdn.jsdelivr.net/fancybox/2.1.5/helpers/jquery.fancybox-thumbs.js"></script>
  <link type="text/css" rel="stylesheet" href="//cdn.jsdelivr.net/fancybox/2.1.5/jquery.fancybox.css" />
  <script type="text/javascript" src="//cdn.jsdelivr.net/fancybox/2.1.5/jquery.fancybox.js"></script>
  <script type="text/javascript" src="//cdn.jsdelivr.net/fancybox/2.1.5/jquery.fancybox.pack.js"></script>
  <!-- Fancy Box -->

  <!-- JQuery End -->
  
  <script type="text/javascript" src="common.js"></script>

  {block name="head"}{/block}
</head>
<body>
  {block name="body"}
  {/block}
  <hr />
  <p style="text-align: center;">
    Archived by CrzySdrs <br />
    <a href="https://twitter.com/intent/tweet?screen_name=crzysdrs" class="twitter-mention-button">Tweet to @crzysdrs</a>
    {literal}
    <script type="text/javascript">!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
    {/literal}
  </p>
  {if (isset($breadcrumbs)) }
  <hr />  
  {foreach $breadcrumbs as $b}
  <span typeof="v:Breadcrumb">
    <a href="{$b.url|escape}" rel="v:url" property="v:title">
      {$b.title}
    </a>
    {if !$b@last}
    &gt;
    {/if}
  </span>
  {/foreach}
  {/if}
</body>
</html>
