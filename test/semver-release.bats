#!/usr/bin/env bats

setup() {
	BIN="$(cd "$(dirname "$BATS_TEST_FILENAME")/../bin" && pwd)/semver-release"
	WORKDIR="$(mktemp -d)"
	REMOTE="$WORKDIR/remote.git"
	REPO="$WORKDIR/repo"

	git init -q --bare "$REMOTE"

	git init -q "$REPO"
	cd "$REPO" || return 1
	git config user.email "test@example.com"
	git config user.name "Test"
	git remote add origin "$REMOTE"

	git commit -q --allow-empty -m "feat: initial feature"
	git push -q origin HEAD:main 2>/dev/null || git push -q origin HEAD:master
}

teardown() {
	rm -rf "$WORKDIR"
}

@test "dry-run makes no filesystem or git changes" {
	run "$BIN" --version 1.0.0 --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *"1.0.0"* ]]
	[ ! -f "CHANGELOG.md" ]
	run git rev-parse -q --verify refs/tags/v1.0.0
	[ "$status" -ne 0 ]
}

@test "releases a version: tags, updates changelog, and pushes" {
	run "$BIN" --version 1.0.0
	[ "$status" -eq 0 ]

	run git rev-parse -q --verify refs/tags/v1.0.0
	[ "$status" -eq 0 ]

	[ -f "CHANGELOG.md" ]
	grep -q "^# 1.0.0 " CHANGELOG.md
	grep -q "### Features" CHANGELOG.md

	run git --git-dir="$REMOTE" rev-parse -q --verify refs/tags/v1.0.0
	[ "$status" -eq 0 ]
}

@test "reads the version from the default version file when --version is omitted" {
	printf '1.0.0' >./version

	run "$BIN"
	[ "$status" -eq 0 ]
	run git rev-parse -q --verify refs/tags/v1.0.0
	[ "$status" -eq 0 ]
}

@test "is idempotent: a second run against an already-released tag is a no-op" {
	"$BIN" --version 1.0.0
	first_head=$(git rev-parse HEAD)

	run "$BIN" --version 1.0.0
	[ "$status" -eq 0 ]
	[ "$(git rev-parse HEAD)" = "$first_head" ]
}

@test "groups Features, Bug Fixes, and Other Changes separately" {
	git commit -q --allow-empty -m "fix: a bug"
	git commit -q --allow-empty -m "chore: tidy up"

	"$BIN" --version 1.0.0

	grep -A2 "### Features" CHANGELOG.md | grep -q "initial feature"
	grep -A2 "### Bug Fixes" CHANGELOG.md | grep -q "a bug"
	grep -A2 "### Other Changes" CHANGELOG.md | grep -q "tidy up"
}

@test "first release heading has no compare-link brackets" {
	"$BIN" --version 1.0.0
	grep -q "^# 1.0.0 (" CHANGELOG.md
}

@test "a subsequent release with a compare-url-template gets a bracketed, linked heading" {
	"$BIN" --version 1.0.0
	git commit -q --allow-empty -m "feat: a second feature"

	"$BIN" --version 1.1.0 \
		--compare-url-template "https://example.test/compare/{prev}...{new}"

	grep -q "^# \[1.1.0\](https://example.test/compare/v1.0.0...v1.1.0) (" CHANGELOG.md
}

@test "runs the release hook with version, tag, and notes-file env vars" {
	hook_out="$WORKDIR/hook-out.txt"
	hook="$WORKDIR/hook.sh"
	cat >"$hook" <<EOF
#!/usr/bin/env bash
{
	echo "version=\$SEMVER_VERSION"
	echo "tag=\$SEMVER_TAG"
	echo "notes-has-content=\$( [ -s "\$SEMVER_NOTES_FILE" ] && echo yes || echo no )"
} >"$hook_out"
EOF
	chmod +x "$hook"

	"$BIN" --version 1.0.0 --release-hook "$hook"

	run cat "$hook_out"
	[[ "$output" == *"version=1.0.0"* ]]
	[[ "$output" == *"tag=v1.0.0"* ]]
	[[ "$output" == *"notes-has-content=yes"* ]]
}

@test "fails with a usage error when no version is given and no version file exists" {
	run "$BIN"
	[ "$status" -eq 2 ]
}
