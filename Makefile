CARGO = cargo --color always

build: build_debug

build_debug:
	@$(CARGO) build --all --all-targets

all: check_format build_debug clippy test doc

clean:
	@$(CARGO) clean

install:
	@$(CARGO) install --path .

test:
	@$(CARGO) test --all

doc:
	@$(CARGO) doc

check_format:
	@$(CARGO) fmt -- --check
	@$(CARGO) tomlfmt -d -p Cargo.toml

format:
	@$(CARGO) fmt
	@$(CARGO) tomlfmt -p Cargo.toml

clippy:
	@$(CARGO) clippy \
		--all-targets -- \
		-D warnings \
		-W clippy::cast_possible_truncation \
		-W clippy::cast_sign_loss \
		-W clippy::fallible_impl_from \
		-W clippy::cast_precision_loss \
		-W clippy::cast_possible_wrap \
		-W clippy::dbg_macro