function main() {
  $.get(
    "https://api.github.com/repos/KonnexionsGmbH/ora_bench/contents/results?ref=gh-pages",
    function (data) {
      $.each(data, function (key, val) {
        if (val.name.match(/\.tsv/) !== null) {
          show_tsv(val.name, val.download_url);
        }
      });
    }
  )
}

function show_tsv(name, url) {
  console.log(name, url);
  $.get(url, function (data) {
    var lines = data.match(/[^\r\n]+/g);
    for (var i = 0; i < lines.length; ++i)
      lines[i] = lines[i].split("\t");
    var columns = [];
    var tfoot = $('<tfoot>').appendTo('#result');
    var tfoottr = $('<tr>').appendTo(tfoot);
    for (var i = 0; i < lines[0].length; ++i) {
      columns.push({ title: lines[0][i], visible: i > 6 });
      tfoottr.append($('<th>'));
    }
    lines.shift();
    $('#result').DataTable({
      dom: 'Blfrtip',
      buttons: ['colvis'],
      data: lines,
      columns: columns,
      initComplete: function () {
        this.api().columns().every(function () {
          var column = this;
          var select = $('<select><option value=""></option></select>')
            .appendTo($(column.footer()).empty())
            .on('change', function () {
              var val = $.fn.dataTable.util.escapeRegex(
                $(this).val()
              );

              column
                .search(val ? '^' + val + '$' : '', true, false)
                .draw();
            });
          column.data().unique().sort().each(function (d, j) {
            select.append('<option value="' + d + '">' + d + '</option>')
          });
        });
      }
    });
  });
}

$(document).ready(main);
