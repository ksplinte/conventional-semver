# commit-lint

Validates commit subjects against the [Conventional Commits](https://www.conventionalcommits.org/)
spec: `type(scope)!: subject`.

## Usage

```sh
commit-lint --message "feat: add a new thing"
commit-lint --range origin/main..HEAD
```

## Options

| Flag | Description | Default |
| --- | --- | --- |
| `--message <string>` | Lint a single commit subject/body string. | |
| `--range <rev>..<rev>` | Lint every commit reachable in the given git range. | |
| `--types <csv>` | Comma-separated allowed types. | `feat,fix,docs,style,refactor,perf,test,build,ci,chore,revert` |
| `--skip-pattern <regex>` | Extended-regex subject pattern to skip, in addition to merge commits. | `^chore\(release\):` |

Exactly one of `--message` or `--range` is required.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | all linted commits pass |
| `1` | one or more commits failed linting |
| `2` | usage error |

## Notes

- Merge commits (subject starting with `Merge `) are always skipped.
- Commits matching `--skip-pattern` are skipped - by default this covers
  `semver-release`'s own `chore(release): ...` commits, so a release commit
  never fails its own lint check on the next run.
- All diagnostics are written to stderr; stdout is left clean.
