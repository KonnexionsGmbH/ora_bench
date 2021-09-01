.DEFAULT_GOAL := build

deps:
	go get golang.org/x/xerrors
	go get github.com/godror/godror
.PHONY:deps

tidy: deps
	go mod tidy
.PHONY:tidy

fmt: tidy
	go fmt ./cmd
.PHONY:fmt

vet: fmt
	go vet ./cmd
.PHONY:vet

build: vet
	go build cmd/orabench.go
.PHONY:build
