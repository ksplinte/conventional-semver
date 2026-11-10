#!/usr/bin/env bats

setup() {
	BIN="$(cd "$(dirname "$BATS_TEST_FILENAME")/../bin" && pwd)/commit-lint"
	REPO="$(mktemp -d)"
	cd "$REPO" || return 1
	git init -q
	git config user.email "test@example.com"
	git config user.name "Test"
}

teardown() {
	rm -rf "$REPO"
}

@test "accepts a valid conventional commit message" {
	run "$BIN" --message "feat: add a new thing"
	[ "$status" -eq 0 ]
}

@test "accepts a message with a scope" {
	run "$BIN" --message "fix(parser): handle empty input"
	[ "$status" -eq 0 ]
}

@test "accepts a breaking-change marker" {
	run "$BIN" --message "feat!: drop support for v1 config"
	[ "$status" -eq 0 ]
}

@test "rejects a message with no conventional type" {
	run "$BIN" --message "add a new thing"
	[ "$status" -eq 1 ]
}

@test "rejects an unknown type" {
	run "$BIN" --message "oops: this is not a real type"
	[ "$status" -eq 1 ]
}

@test "rejects a trailing period" {
	run "$BIN" --message "feat: add a new thing."
	[ "$status" -eq 1 ]
}

@test "honours a custom --types list" {
	run "$BIN" --types "feat,fix" --message "docs: update readme"
	[ "$status" -eq 1 ]
}

@test "requires exactly one of --message or --range" {
	run "$BIN"
	[ "$status" -eq 2 ]

	run "$BIN" --message "feat: x" --range HEAD..HEAD
	[ "$status" -eq 2 ]
}

@test "lints every commit in a range, failing on any bad one" {
	git commit -q --allow-empty -m "chore: root"
	root=$(git rev-parse HEAD)
	git commit -q --allow-empty -m "feat: first"
	git commit -q --allow-empty -m "not conventional"
	git commit -q --allow-empty -m "fix: second"

	run "$BIN" --range "${root}..HEAD"
	[ "$status" -eq 1 ]
	[[ "$output" == *"not conventional"* ]]
}

@test "skips merge commits and the tool's own release commits in --range mode" {
	git commit -q --allow-empty -m "chore: root"
	root=$(git rev-parse HEAD)
	git commit -q --allow-empty -m "feat: first"
	git commit -q --allow-empty -m "Merge branch 'x' into main"
	git commit -q --allow-empty -m "chore(release): 1.0.0 [skip ci]"

	run "$BIN" --range "${root}..HEAD"
	[ "$status" -eq 0 ]
}

@test "passes on an empty range" {
	git commit -q --allow-empty -m "feat: first"
	run "$BIN" --range "HEAD..HEAD"
	[ "$status" -eq 0 ]
}
