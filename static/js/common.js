
jQuery.expr[':'].regex = function(elem, index, match) {
    var matchParams = match[3].split(','),
        validLabels = /^(data|css):/,
        attr = {
            method: matchParams[0].match(validLabels) ?
                        matchParams[0].split(':')[0] : 'attr',
            property: matchParams.shift().replace(validLabels,'')
        },
        regexFlags = 'ig',
        regex = new RegExp(matchParams.join('').replace(/^\s+|\s+$/g,''), regexFlags);
    return regex.test(jQuery(elem)[attr.method](attr.property));
}


function article_jquery(base_url) {
    $(':regex(href,/victim/[0-9]+)').qtip({
	style: {classes:'qtip-light qtip-shadow myCustomClass'},
	position: {
	    my: 'bottom left',
	    at: 'top right',
	    target: 'mouse',
	    viewport: $(window),
	},
	show: {
	    effect: false,
	},
	content: {
	    text: function(event, api) {
		var id = $(this).attr('href').match(/\/victim\/([0-9]+)/)[1];
		$.ajax({
		    url: base_url + '/js/json/articles.json',
		    type: 'GET',
		    dataType: 'json',
		}).then(function(data) {
		    var data_id = data[id];
		    var content = '<img style="float: left"; height="100px" width="100px" src="' + base_url + '/img/' + data_id['vicsmall'] + '" />';
		    content += '<div style="float: right;">';
		    content += '<table>';
		    content += '<tr><td><strong>Date</strong></td><td>' + data_id['date'] + '</td></tr>';
		    content += '<tr><td><strong>Score</strong></td><td>' + data_id['score'].toFixed(2) + '</td></tr>';
		    content += '<tr><td><strong>Votes</strong></td><td>' + data_id['votes'] + '</td></tr>';
		    content += '</table>';
		    content += '</div>';
		    api.set('content.text',content);
		    api.set('content.title',data_id.title);
		}, function(xhr, status, error) {
		    api.set('content.title', status);
		    api.set('content.text', error);
		});
		return 'Loading...';
	    }
	}
    });
    // $(':regex(href,\\.(jpe?g|png|gif)$)').fancybox();
    $("a[href$='.jpg'],a[href$='.jpeg'],a[href$='.png'],a[href$='.gif']").attr('rel', 'gallery').fancybox();
    $(':regex(href,^http://web.archive.org)').qtip({
	style: {classes:'qtip-light qtip-shadow myCustomClass'},
	content: {
	    text:'Since many pages referenced in Daily Victims no longer exist, this link is to an archived version of the website on the date this Daily Victim was posted.',
	    title:'Wayback Machine',
	}
    });
}
