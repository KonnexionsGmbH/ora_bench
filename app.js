$(document).ready(function () {
    console.log("ready!");
    $.get("results/ora_bench_result.tsv", function (data) {
        console.log(data);
    })
});