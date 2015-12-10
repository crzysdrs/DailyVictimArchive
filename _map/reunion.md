---
title: Daily Victim Reunion
tile_loc: tiles/reunion/
tile_name: reunion
min_zoom: 0
max_zoom: 5

head: >
    <script type="text/javascript" src="http://code.jquery.com/jquery-1.8.3.js"></script>
    <script type="text/javascript" src="reunion.json"></script>
    <script type="text/javascript" src="reunion.js"></script>

map_init: >
    map.setZoom(2);
    init_polys(map);
    
---

