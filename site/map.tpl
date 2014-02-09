<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN"
	  "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:foaf="http://xmlns.com/foaf/0.1/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      version="XHTML+RDFa 1.0" xml:lang="en" style="height: 100%; width:100%;">
  <head>
    <meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
    <title>{block name="title"}Daily Victim Archive Google Map{/block}</title>
    <script type="text/javascript" src="http://maps.google.com/maps/api/js?libraries=geometry&sensor=false"></script>
    <script type="text/javascript" src="map.js"></script>
    <script type="text/javascript">
      function do_map() {
      var map = init_map('google-map', '{$tile_loc}', '{$tile_name}',
      {$min_zoom|default:0}, {$max_zoom|default:5});
      {block name="do_map"}{/block}
      map.controls[google.maps.ControlPosition.TOP_RIGHT].push(new DVBox());
      }
    </script>
    {block name="head"}{/block} 
  </head>
  <body style="width:100%; height:100%; margin:0;" onload="do_map();">
    <div id="google-map" style="width:100%;height:100%;"></div>
  </body>
</html>
