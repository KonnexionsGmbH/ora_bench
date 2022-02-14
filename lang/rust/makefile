.DEFAULT_GOAL := build

fmt:
	cargo fmt
.PHONY:clippy

clippy: fmt
	cargo clippy
.PHONY:build

build: clippy
	cargo build $(release)
	cargo install --list
.PHONY:build

