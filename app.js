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
        for (var i = 0; i < lines[0].length; ++i)
            columns.push({ title: lines[0][i], visible: i > 6 });
        console.debug('columns', columns);
        lines.shift();
        console.debug('data', lines);

        var table = $('#result').DataTable({
            dom: 'Blfrtip',
            orderCellsTop: true,
            fixedHeader: true,
            buttons: ['colvis'],
            data: lines,
            columns: columns
        });

        $('#result thead tr').clone(true).appendTo('#result thead');
        $('#result thead tr:eq(1) th').each(function (i) {
            var title = $(this).text();
            $(this).html('<input type="text" placeholder="Search ' + title + '" />');

            $('input', this).on('keyup change', function () {
                if (table.column(i).search() !== this.value) {
                    console.log("here");
                    table
                        .column(i)
                        .search(this.value)
                        .draw();
                }
            });
        });
    });
}

$(document).ready(main);