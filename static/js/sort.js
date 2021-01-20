  jQuery.extend( jQuery.fn.dataTableExt.oSort, {
    "formatted-num-pre": function ( a ) {
        a = (a === "-" || a === "") ? 0 : a.replace( /[^\d\-\.]/g, "" );
        return parseFloat( a );
    },

    "formatted-num-asc": function ( a, b ) {
        return a - b;
    },

    "formatted-num-desc": function ( a, b ) {
        return b - a;
    }
  } );

  jQuery.fn.dataTableExt.aTypes.unshift(
    function ( sData )
    {
	if (sData.match(/^-?[0-9]{1,3}(,[0-9]{3})*(\.[0-9]+)?$/ig)) {
            return 'formatted-num';
	} else {
	    return null;
	}
    }
);

$(document).ready(function(){
  $('#meta_articles').dataTable(
    {
      "bPaginate":false,
      "bInfo":false,
      "bStateSave":true,
      "responsive":true,
      "columnDefs": [
        { responsivePriority: 1, targets: 1 },
        { responsivePriority: 2, targets: 0 },
      ],
    }
  );
  $('#maps').dataTable(
    {
      "bPaginate":false,
      "bInfo":false,
      "bStateSave":true,
      "responsive":true,
      "columnDefs": [
        { responsivePriority: 1, targets: 0 },
      ],
    }
  );
  $('#dailyvictims').dataTable(
    {
      "bPaginate":false,
      "bInfo":false,
      "bStateSave":true,
      "responsive":true,
      "columnDefs": [
        { responsivePriority: 1, targets: -1 },
        { responsivePriority: 2, targets: 0 }
      ],
      "aaSorting": [[0, "asc"]],

    }
  ).on('mouseenter', 'tr[data-vicpicsmall]', function (event) {
    var img = $(this).data('vicpicsmall');
    $(this).qtip({
      style: {classes:'qtip-light qtip-shadow myCustomClass'},
      overwrite: false,
      content: '<img style="height: 100px; width: 100px;" src="img/' + img + '"/>',
      position: {
        my: 'bottom left',
        at: 'top right',
        target: $('td', this),
        //target: 'mouse',
        viewport: $('#dailyvictims')
      },
      show: {
        event: event.type,
        ready: true,
      },
      hide: {
        fixed: true
      }
    }, event);
  });
});
