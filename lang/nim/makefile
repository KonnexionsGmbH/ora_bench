.DEFAULT_GOAL := build

deps:
	nimble install nimodpi
	nimble install nimterop -y
.PHONY:deps

tidy: deps
	go mod tidy
.PHONY:tidy

build: tidy
	nim compile -d:release -o=lang\nim\bin\ lang\nim\src\ora_bench.nim
.PHONY:build
