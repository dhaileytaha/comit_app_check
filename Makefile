RUSTUP = rustup

TOOLCHAIN = $(shell cat rust-toolchain)
CARGO = $(RUSTUP) run --install $(TOOLCHAIN) cargo --color always

NIGHTLY_TOOLCHAIN = "nightly-2019-07-31"
CARGO_NIGHTLY = $(RUSTUP) run --install $(NIGHTLY_TOOLCHAIN) cargo --color always

# cannot use the unix-socket to talk to the docker daemon on windows
ifeq ($(OS),Windows_NT)
    BUILD_ARGS = --no-default-features --features windows
    TEST_ARGS = --no-default-features --features windows
    INSTALL_ARGS = --no-default-features --features windows
endif

.PHONY: install_rust install_rust_nightly install_clippy install_rustfmt install_tomlfmt install clean all format build build_debug release clippy test doc check_format e2e_scripts e2e

default: build

install_rust:
	$(RUSTUP) install $(TOOLCHAIN)

install_rust_nightly:
	$(RUSTUP) install $(NIGHTLY_TOOLCHAIN)

## Dev environment

install_clippy: install_rust
	$(RUSTUP) component list --installed --toolchain $(TOOLCHAIN) | grep -q clippy || $(RUSTUP) component add clippy --toolchain $(TOOLCHAIN)

# need nightly toolchain to get access to `merge_imports`
install_rustfmt: install_rust_nightly
	$(RUSTUP) component list --installed --toolchain $(NIGHTLY_TOOLCHAIN) | grep -q rustfmt || $(RUSTUP) component add rustfmt --toolchain $(NIGHTLY_TOOLCHAIN)

install_tomlfmt: install_rust
	$(CARGO) --list | grep -q tomlfmt || $(CARGO) install cargo-tomlfmt

## User install

install:
	$(CARGO) install --force --path . $(INSTALL_ARGS)

clean:
	$(CARGO) clean

## Development tasks

all: format build_debug clippy test doc e2e_scripts

format: install_rustfmt install_tomlfmt
	$(CARGO_NIGHTLY) fmt
	$(CARGO) tomlfmt -p Cargo.toml

build: build_debug

build_debug:
	$(CARGO) build --all --all-targets $(BUILD_ARGS)

release:
	$(CARGO) build --all --all-targets --release $(BUILD_ARGS)

clippy: install_clippy
	$(CARGO) clippy --all-targets -- -D warnings

test:
	$(CARGO) test --all $(TEST_ARGS)

doc:
	$(CARGO) doc

check_format: install_rustfmt install_tomlfmt
	$(CARGO_NIGHTLY) fmt -- --check
	$(CARGO) tomlfmt -d -p Cargo.toml

yarn_install_all:
	(cd ./.npm; yarn install)
	(cd ./new_project/examples/btc_eth; yarn install)
	(cd ./new_project/examples/erc20_btc; yarn install)
	(cd ./new_project/examples/separate_apps; yarn install)

check_lock_files: build_debug yarn_install_all
	(! git status -s | grep -q lock) # If a lock file was changed, this returns 1 otherwise 0

e2e_scripts:
	./tests/new.sh
	./tests/start_env.sh
	./tests/force_clean_env.sh
	./tests/btc_eth.sh

e2e: build_debug e2e_scripts
