.DEFAULT_GOAL := build

clean:
	cargo clean
.PHONY:fmt

fmt: clean
	cargo fmt
.PHONY:clippy

clippy: fmt
	cargo clippy
.PHONY:tidy

build: clippy
	cargo build $(release)
.PHONY:build
