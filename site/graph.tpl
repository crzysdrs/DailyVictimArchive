{extends file='map.tpl'}
{block name='head'}
<script type="text/javascript" src="dags/all_poly.js"></script>
<script type="text/javascript" src="graph.js"></script>
{/block}
{block name="do_map"}
init_polys(map);
{if isset($id)}
var selected = polys[{$id}]['poly'];
var point = selected.getPath().getAt(2);
map.setZoom(4);
map.setCenter(point);
var event = { latLng:point };
google.maps.event.trigger(selected, 'click', event);
{/if}
{/block}
</script>