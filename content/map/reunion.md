---
title: Daily Victim Reunion
template: map.html
description: A group photo of all Daily Victims.
    
extra:
    tile_name: reunion
    min_zoom: 0
    max_zoom: 5

    head: >
        <script type="text/javascript" src="{{ site.baseurl | append: "js/reunion.js" }}"></script>

    map_init: >
        map.setZoom(2);
        console.log("Do Map");
        var polys, urls, articles;
        $.when(
            $.getJSON( "{{ site.baseurl }}/js/json/reunion.json", function( json ) {
                polys = json;
            }).error(function(jqXHR, textStatus, errorThrown) { console.log("json error: " + textStatus);}),
        $.getJSON( "{{ site.baseurl }}/js/json/articles.json", function( json ) {
            articles = json;
        }).error(function(jqXHR, textStatus, errorThrown) { console.log("json error: " + textStatus);})
        ).then(function() {
            init_polys({{ site.baseurl }}, map, articles, polys);
        });
---

