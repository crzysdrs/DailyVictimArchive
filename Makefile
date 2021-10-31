.DEFAULT_GOAL: all
.PHONY: extract all serve deploy build

all:
	cargo run --manifest-path src/rust/Cargo.toml --bin gen --release -- \
		  --root-dir .
extract:
	git annex init
	git remote add blockade_annex http://git.crzysdrs.net/git/DailyVictimArchive.git
	git annex get .

build:
	zola build

serve:
	zola serve -i 0.0.0.0 -u localhost

deploy:
	zola build --output-dir deploy
