var map;
var reunion_json;
var reunion_img_size = Math.pow(2,5);

function create_path(lines) {
    var polys = [];
    for (var y = 0; y < lines.length; y++) {
	var gpoints = [];
	for (var x = 0; x < lines[y].length; x += 2) {
	    gpoints.push(convert(new google.maps.Point(lines[y][x], lines[y][x+1]), reunion_img_size));
	}
	if (y > 0) {
	    gpoints = gpoints.reverse();
	}
	polys.push(gpoints);
    }
    return polys;
}

var cur_info = null;
function make_bio(bio) {
    return function(event) {
	var title;
	var content;
	var twitter;
	if (cur_info) {
	    cur_info.setMap(null);
	}
	if (bio == "fargo") {
	    twitter = "DaveKosak";
	    title = 'Dave "Fargo" Kosak';
	    content = "Fargo realized early in life that he wanted to be a Space Marine. However, our foolish political leaders continue to hem and haw and refuse to arm our people with a military space force -- must we wait until it's too late? When will they learn!? Also, he had eyesight problems that prevent him from being an astronaut. Instead, Fargo became a writer -- a gaming journalist who's been active in the online gaming community since the days of Quake. Fargo was GameSpy's first employee, resulting in a company culture that continues to resemble beanbag toss day at the preschool.";
	} else if (bio == "hotsoup") {
	    twitter = "Lemmo";
	    title = 'Lemuel "HotSoup" Pew';
	    content = "Here we have the resident artist known as Hot Soup. Banished from his sacred brotherhood of underground assassins, only because he won't take off that silly hat, Soup now works as the artistic counterpart to Fargo. Spending many late nights scribbling out whatever ridiculous ideas might pour from the brains of these two, Soup does his best to represent hilarity in pictorial form. His ultimate goal in life is to find \"The Very Funny Shape,\" a special polygon that brings reams of gut-wrenching laugher to anyone unfortunate enough to catch it out of the corner of the eye. The Soup spent the last couple years putting his artwork online, and his credentials include, but are not limited to, the online comics Lethal Doses and Winter.";
	} else if (bio == "gabe") {
	    twitter = "cwGabriel";
	    title = 'Mike "Gabriel" Krahulik';
	    content = 'The first 300 or so Victims in the archives were the work of this immensely talented artist, who has since moved on to other things. "Gabe," as he is known, was artifically created in an enormous, bubbling vat, surrounded by blinking lights that have little to no significance. After his career as a zeppelin pilot was cut tragically short, he pursued the life of an artist. Since then he teamed up with Jerry "Tycho" Holkins and together they founded Penny-Arcade, an awesome gaming comic strip, as well as The Bench.org, which can best be described as "open-source cartooning." Gabe used to do much of the illustration work for GameSpy.com and his work still sorta sets the "feel" of the site. Blame him.';
	}

	var infoWindow = new google.maps.InfoWindow({
	    content: "<strong>" + title + "</strong> <a href=\"http://twitter.com/" + twitter + "\">@" + twitter + "</a><br />" + content,
	    maxWidth:300
	});
	infoWindow.setPosition(event.latLng);
	infoWindow.open(map);
	cur_info = infoWindow;
    }
}
function make_click(ids) {
    return function(event) {
	//reunion_json[id]['poly'].setOptions({strokeOpacity:1});
	jQuery.ajax({
	    url: 'json_article.php',
	    type: 'GET',
	    dataType: 'json',
	    data: {
		id: ids
	    },
	}).then(function(data) {
	    if (cur_info) {
		cur_info.setMap(null);
	    }
	    var content = "<div>";
	    for (var id in data) {
		var data_id = data[id];
		content += '<div style="overflow: auto;">';
		content += '<div><a href="article.php?id=' + id + '">' + data_id.title + '</a></div>';
		content += '<div>';
		content += '<img style="float: left; height:100px; width:100px;" src="img/' + data_id.vicpic_small + '" />';
		content += '<div style="float: right;">';
		content += '<table>';
		content += '<tr><td><strong>Date</strong></td><td>' + data_id.date + '</td></tr>';
		content += '<tr><td><strong>Score</strong></td><td>' + data_id.avg.toFixed(2) + '</td></tr>';
		content += '<tr><td><strong>Votes</strong></td><td>' + data_id.votes + '</td></tr>';
		content += '</table>';
		content += '</div>';
		content += '</div>';
		content += '</div>';
	    }
	    content += "</div>";
	    var infoWindow = new google.maps.InfoWindow({
		content: content,
		maxWidth:300
	    });
	    infoWindow.setPosition(event.latLng);
	    infoWindow.open(map);
	    cur_info = infoWindow;
	}, function(xhr, status, error) {
	    var infoWindow = new google.maps.InfoWindow({
		content:error
	    });
	    if (cur_info) {
		cur_info.setMap(null);
	    }
	    infoWindow.setPosition(event.latLng);
	    infoWindow.open(map);
	    cur_info = infoWindow;
	});
    }
}

function init_polys(set_map) {
    map = set_map;
    reunion_json = window.reunion_json;
    for (var x in reunion_json) {
	var opacity = 0;

	reunion_json[x]['poly'] = new google.maps.Polygon({
	    paths:create_path(reunion_json[x]['lines']),
	    strokeColor:"#f33f00",
	    strokeWeight:1, 
	    strokeOpacity:opacity,
	    fillColor:"#ff0000",
	    fillOpacity:opacity / 2,
	    zIndex:reunion_json[x]['z_index']
	});
	reunion_json[x]['poly'].setMap(map);
	if (!isNaN(parseInt(x))) {
	    google.maps.event.addListener(reunion_json[x]['poly'], 'click', make_click(reunion_json[x].ids));
	} else {
	    google.maps.event.addListener(reunion_json[x]['poly'], 'click', make_bio(x));
	}
    }
}