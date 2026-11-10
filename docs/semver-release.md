# semver-release

Tags a release, updates `CHANGELOG.md`, commits, and pushes. Platform-specific
steps (creating a GitHub/GitLab Release object, notifying Slack, etc.) are
deliberately **not** built in - use `--release-hook` instead.

## Usage

```sh
semver-next --output-file ./version
semver-release   # reads ./version by default
```

or in one shot:

```sh
semver-release --version "$(semver-next --print)"
```

## Options

| Flag | Description | Default |
| --- | --- | --- |
| `--version <X.Y.Z>` | Version to release. | read from `--version-file` |
| `--version-file <path>` | Where to read the version when `--version` is omitted. | `./version` |
| `--tag-prefix <str>` | Prefix for the git tag. | `v` |
| `--changelog-file <path>` | Changelog to prepend to. | `CHANGELOG.md` |
| `--commit-url-template <t>` | Per-commit link template, `{sha}` placeholder. | none (plain short SHA) |
| `--compare-url-template <t>` | Release-heading link template, `{prev}`/`{new}` placeholders (tag names). | none (no link) |
| `--remote <name-or-url>` | Git remote to push to. | `origin` |
| `--push-token <token>` | If `--remote` is an `https://` URL, injects `x-access-token:<token>@` into it before pushing. | |
| `--release-hook <path>` | Executable run after a successful tag + push. | |
| `--dry-run` | Compute and print everything; touch nothing on disk, make no commits/tags/pushes. | |

## Idempotency

Before doing anything, `semver-release` checks whether the tag already
exists (on the remote for a real run, locally for `--dry-run`). If it does,
the tool logs that and exits `0` without making changes - safe to re-run on
a flaky pipeline retry.

## The release hook

If `--release-hook` is given, it's run **after** the tag and changelog commit
are pushed, with:

| Env var | Contents |
| --- | --- |
| `SEMVER_VERSION` | The bare version, e.g. `1.2.3` |
| `SEMVER_TAG` | The full tag, e.g. `v1.2.3` |
| `SEMVER_NOTES_FILE` | Path to a file containing just this release's notes |

This is the extension point for anything platform-specific - the bundled
[GitHub Action](../action.yml) uses it to call `gh release create`.

## Changelog format

Entries are grouped into `### Features` / `### Bug Fixes` / `### Other
Changes` (perf, chore, docs, refactor, style, revert, build, ci, test lumped
together) under a `# X.Y.Z (YYYY-MM-DD)` heading (bracketed and linked to
`--compare-url-template` when there's a previous tag to compare against).

## Exit codes

`0` on success (including the idempotent no-op case) or `--dry-run`. `1` if
a release step fails. `2` on a usage error.
