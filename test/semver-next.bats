#!/usr/bin/env bats

setup() {
	BIN="$(cd "$(dirname "$BATS_TEST_FILENAME")/../bin" && pwd)/semver-next"
	REPO="$(mktemp -d)"
	cd "$REPO" || return 1
	git init -q
	git config user.email "test@example.com"
	git config user.name "Test"
}

teardown() {
	rm -rf "$REPO"
}

@test "first release: a feat commit with no prior tag bumps minor from 0.0.0" {
	git commit -q --allow-empty -m "feat: initial feature"

	run "$BIN" --print
	[ "$status" -eq 0 ]
	[ "$output" = "0.1.0" ]
}

@test "first release: a fix-only history bumps patch from 0.0.0" {
	git commit -q --allow-empty -m "fix: initial fix"

	run "$BIN" --print
	[ "$status" -eq 0 ]
	[ "$output" = "0.0.1" ]
}

@test "no releasable commits: prints nothing on stdout and exits 0" {
	git commit -q --allow-empty -m "chore: housekeeping"

	run bash -c "'$BIN' --print 2>/dev/null"
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "writes the bumped version to the output file by default" {
	git commit -q --allow-empty -m "feat: initial feature"

	run "$BIN"
	[ "$status" -eq 0 ]
	[ -f "./version" ]
	[ "$(cat ./version)" = "0.1.0" ]
}

@test "does not write an output file when there is nothing to release" {
	git commit -q --allow-empty -m "docs: update readme"

	run "$BIN"
	[ "$status" -eq 0 ]
	[ ! -f "./version" ]
}

@test "bumps patch from an existing tag on a fix commit" {
	git commit -q --allow-empty -m "feat: initial"
	git tag v1.2.3
	git commit -q --allow-empty -m "fix: a bug"

	run "$BIN" --print
	[ "$output" = "1.2.4" ]
}

@test "bumps minor from an existing tag on a feat commit" {
	git commit -q --allow-empty -m "feat: initial"
	git tag v1.2.3
	git commit -q --allow-empty -m "feat: another feature"

	run "$BIN" --print
	[ "$output" = "1.3.0" ]
}

@test "a breaking-change marker bumps major and resets minor/patch" {
	git commit -q --allow-empty -m "feat: initial"
	git tag v1.2.3
	git commit -q --allow-empty -m "feat!: breaking rewrite"

	run "$BIN" --print
	[ "$output" = "2.0.0" ]
}

@test "a BREAKING CHANGE footer bumps major even on a fix" {
	git commit -q --allow-empty -m "feat: initial"
	git tag v1.2.3
	git commit -q --allow-empty -m "fix: patch something

BREAKING CHANGE: removes the old flag"

	run "$BIN" --print
	[ "$output" = "2.0.0" ]
}

@test "the highest bump among multiple commits wins" {
	git commit -q --allow-empty -m "feat: initial"
	git tag v1.2.3
	git commit -q --allow-empty -m "fix: small fix"
	git commit -q --allow-empty -m "feat: a feature"
	git commit -q --allow-empty -m "chore: cleanup"

	run "$BIN" --print
	[ "$output" = "1.3.0" ]
}

@test "honours a custom --tag-prefix" {
	git commit -q --allow-empty -m "feat: initial"
	git tag "release-1.0.0"
	git commit -q --allow-empty -m "fix: a bug"

	run "$BIN" --tag-prefix "release-" --print
	[ "$output" = "1.0.1" ]
}

@test "ignores merge commit subjects" {
	git commit -q --allow-empty -m "feat: initial"
	git tag v1.0.0
	git commit -q --allow-empty -m "Merge branch 'feature/x'"

	run bash -c "'$BIN' --print 2>/dev/null"
	[ -z "$output" ]
}
