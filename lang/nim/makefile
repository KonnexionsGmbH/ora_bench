.DEFAULT_GOAL := build

deps:
	nimble install nimodpi -y
	nimble install nimterop -y
.PHONY:deps

pretty: deps
	nimpretty src/ora_bench.nim
.PHONY:pretty

docs: pretty
	nim doc --hints:off -o=docs/ora_bench.html src/ora_bench.nim
.PHONY:docs

build: docs
	nim compile -d:release --hints:off -o=bin/ora_bench.exe src/ora_bench.nim
.PHONY:build
