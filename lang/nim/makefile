.DEFAULT_GOAL := build

deps:
	nimble install nimodpi -n
	nimble install nimterop -n
.PHONY:deps

tidy: deps
	go mod tidy
.PHONY:tidy

build: tidy
	nim compile -d:release -o=bin/ora_bench.exe src/ora_bench.nim
.PHONY:build
