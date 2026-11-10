# semver-next

Computes the next semantic version from Conventional Commits made since the
last matching tag. Pure: makes no git-history changes and touches the
network only to read local tags/commits (no fetch, no push).

## Usage

```sh
semver-next                          # writes ./version if there's a bump
semver-next --print                  # prints the version instead
semver-next --tag-prefix release-    # custom tag prefix
```

## Bump rules

| Commit type | Bump |
| --- | --- |
| `!` after type/scope, or a `BREAKING CHANGE:` / `BREAKING-CHANGE:` footer | major |
| `feat` | minor |
| `fix`, `perf`, `refactor`, `revert` | patch |
| `docs`, `style`, `test`, `build`, `ci`, `chore` | no bump |

The highest bump found among all commits in range wins. If there is no prior
tag, the base version is `0.0.0`.

## Options

| Flag | Description | Default |
| --- | --- | --- |
| `--tag-prefix <str>` | Prefix of release tags to search for. | `v` |
| `--output-file <path>` | Where to write the bare (no prefix) version. | `./version` |
| `--print` | Print the version to stdout instead of writing a file. | |

## The "no output" contract

When there is nothing releasable, **no file is written** (and `--print`
prints nothing). Consumers should treat a missing/empty version file as "skip
this release" - this is the load-bearing contract `semver-release` and any CI
wiring depend on.

## Exit codes

`0` on success, whether or not a bump was found. `2` on a usage error.
