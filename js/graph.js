var polys;
var map;
var urls;
var articles;
var base_url;

var default_style = {strokeColor:'', strokeWeight:'', strokeOpacity:0};
var modified = new Array();
var lines = new Array();
var map_img_size = Math.pow(2, 5);

function reset_polys() {
    set_polys(modified, default_style);
    for (var x = 0; x < lines.length; x++){
	lines[x].setMap(null);
    }
    lines = new Array();
    modified = new Array();
}

function merge_options(obj1,obj2){
    var obj3 = {};
    for (var attrname in obj1) { obj3[attrname] = obj1[attrname]; }
    for (var attrname in obj2) { obj3[attrname] = obj2[attrname]; }
    return obj3;
}
function set_polys(list, new_style) {
    for (i = 0; i < list.length; i++) {
	polys[list[i]]['poly'].setOptions(new_style);
    }
    modified = modified.concat(list)
}

function set_pred(list) {
    set_polys(list, {strokeColor:'#FF0000', strokeWeight:4, strokeOpacity:0.5});
}
function set_succ(list) {
    set_polys(list, {strokeColor:'#0000FF', strokeWeight:4, strokeOpacity:0.5});
}
function set_selected(list) {
    set_polys(list, {strokeColor:'#00FF00', strokeWeight:4, strokeOpacity:1});
}
function gv_bezier(pts, degree, t) {
    var vtemp = [];
    for (var i = 0; i < degree + 1; i++) {
	vtemp[i] = []
	for (var j = 0; j < degree + 1; j++) {
	    vtemp[i][j] = new google.maps.LatLng(0,0);
	}
    }
    for (var j = 0; j <= degree; j++) {
	    vtemp[0][j] = pts[j];
    }

    for (var i = 1; i <= degree; i++) {
	for (var j = 0; j <= degree -i; j++) {
	    vtemp[i][j] = new google.maps.LatLng(
		(1.0 - t) * vtemp[i - 1][j].lat() + t * vtemp[i-1][j+1].lat(),
		(1.0 - t) * vtemp[i - 1][j].lng() + t * vtemp[i-1][j+1].lng()
	    );
	}
    }
    return vtemp[degree][0];
}
function gv_bz(pts, color) {
    var subdivision = 20;
    var res = [pts[0]];
    var v = [];
    v[3] = pts[0];
    for (var i = 0; i + 3 < pts.length; i += 3) {
	v[0] = v[3];
	for (var j=0; j <= 3; j++) {
	    v[j] = pts[i + j];
	}
	for (step =1; step <= subdivision; step++) {
	    res.push(gv_bezier(v, 3, step / subdivision));
	}
    }
    return new google.maps.Polyline({path:res, strokeColor:color, strokeWeight:10, strokeOpacity:0.5})
}
function draw_polyline(list, color) {
    var p = gv_bz(list, color)
    p.setMap(map);
    lines.push(p);
}

function create_points(list) {
    var gpoints = [];
    for (var i = 0; i < list['xs'].length; i++) {
	var gp = new google.maps.Point(list['xs'][i], list['ys'][i]);
	gpoints.push(convert(gp, map_img_size));
    }
    return gpoints;
}
function draw_outs(id) {
    for (x in polys[id]['outs']) {
	var ps = create_points(polys[id]['outs'][x]);
	draw_polyline(ps, '#0000FF');
    }
}
function draw_ins(id) {
    for (var x = 0; x < polys[id]['preds'].length; x++) {
	var pred = polys[id]['preds'][x];
	for (y in polys[pred]['outs']) {
	    if (y == id) {
		var ps = create_points(polys[pred]['outs'][y]);
		draw_polyline(ps, '#FF0000');
	    }
	}
    }
}
var cur_info = null;
function make_click(id) {
    return function(event) {
	if (cur_info) {
	    cur_info.setMap(null);
	}
	reset_polys();
	set_pred(polys[id]['preds']);
	set_succ(polys[id]['succs']);
	set_selected([id]);
	draw_outs(id);
	draw_ins(id);
	var infoWindow = new google.maps.InfoWindow({
	    content:
	    '<div style="overflow: none;"><a href="'
		+ urls[id] + '">'
		+ articles[id]['title_html'] + '</a></div>',
	    maxWidth:300
	});
	infoWindow.setPosition(event.latLng);
	infoWindow.open(map);
	cur_info = infoWindow;
    }
}

function init_polys(set_base_url, set_map, set_articles, set_polys, set_urls) {
    base_url = set_base_url;
    articles = set_articles;
    map = set_map;
    polys = set_polys;
    urls = set_urls;
    articles = set_articles;
    for (x in polys) {
	polys[x]['poly'] = new google.maps.Polygon({
	    paths:create_points(polys[x]['points']),
	    strokeColor:"#f33f00",
	    strokeWeight:1,
	    strokeOpacity:0,
	    fillColor:"#ff0000",
	    fillOpacity:0.0
	});
	polys[x]['poly'].setMap(map);
	google.maps.event.addListener(polys[x]['poly'], 'click', make_click(x));
    }
}
