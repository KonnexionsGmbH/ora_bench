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
            columns.push({ title: lines[0][i] });
        console.log(columns);
        lines.shift();
        console.log(lines);
        $('#result').DataTable({
            data: lines,
            columns: columns
        });

    });
}

$(document).ready(main);