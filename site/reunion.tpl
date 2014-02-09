{extends file='map.tpl'}
{block name="title"}
Daily Victim Reunion
{/block}
{block name="head"}
<script type="text/javascript" src="http://code.jquery.com/jquery-1.8.3.js"></script>
<script type="text/javascript" src="reunion.json"></script>
<script type="text/javascript" src="reunion.js"></script>
{/block}
{block name="do_map"}
map.setZoom(2);
//map.setCenter(new google.maps.latLng(0, 0));
init_polys(map);
{/block}
