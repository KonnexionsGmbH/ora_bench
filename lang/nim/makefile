.DEFAULT_GOAL := build

deps:
	nimble install nimodpi -n
	nimble install nimterop -n
.PHONY:deps

pretty: deps
	nimpretty src/ora_bench.nim
.PHONY:pretty

docs: pretty
	nim doc  -o=docs/ora_bench.html src/ora_bench.nim
.PHONY:docs

build: docs
	nim compile -d:release -o=bin/ora_bench.exe src/ora_bench.nim
.PHONY:build
