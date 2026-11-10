# conventional-semver

Small, dependency-free bash tools that compute a semantic version from
[Conventional Commits](https://www.conventionalcommits.org/), update a
changelog, tag, and release - a lightweight alternative to
`semantic-release` with no Node.js, no npm supply chain, and no framework
lock-in.

Everything runs on `bash`, `git`, and standard POSIX tools. No runtime
dependencies to audit, install, or fall victim to a supply-chain incident.

## Tools

| Tool | Purpose |
| --- | --- |
| [`bin/commit-lint`](docs/commit-lint.md) | Validate commit subjects against the Conventional Commits spec. |
| [`bin/semver-next`](docs/semver-next.md) | Compute the next version from commits since the last tag. |
| [`bin/semver-release`](docs/semver-release.md) | Update the changelog, tag, and push - with a pluggable hook for anything platform-specific. |

Each is a single self-contained executable script - copy just the one you
need, or use them all together.

## Quickstart (local)

```sh
./bin/commit-lint --range origin/main..HEAD
./bin/semver-next --print
```

## Quickstart (GitHub Actions)

```yaml
on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: your-org/conventional-semver@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

See [`action.yml`](action.yml) for all inputs/outputs. The action computes
the next version, updates `CHANGELOG.md`, tags, pushes, and creates a GitHub
Release - all in one step, and is a no-op when there's nothing releasable.

## Why not semantic-release?

`semantic-release` is powerful but pulls in a large npm dependency tree for
a task that, at its core, is: read commits, do arithmetic on a version
number, write a changelog, push a tag. This project intentionally does only
that core, with a small enough surface area to read end to end in a few
minutes, and no runtime dependency updates to track.

If you need semantic-release's plugin ecosystem (npm publishing, multiple
release branches, etc.), it's still the better choice. If you want the
core conventional-commit-versioning behavior without the dependency
footprint, this project is for you.

## Design

- **CI-agnostic core.** `bin/*` scripts take GitLab/GitHub-specific values
  (remote URLs, tokens, commit/compare link templates) as plain CLI flags -
  nothing reads a `CI_*`/`GITHUB_*` env var directly. Any CI can wire them up.
- **Platform-specific steps are hooks, not built-ins.** Creating a GitHub
  Release, posting to Slack, etc. happens via `semver-release --release-hook`,
  not a hardcoded API call. See [`action.yml`](action.yml) for the GitHub
  Release hook as a worked example.
- **Idempotent by construction.** Re-running `semver-release` against an
  already-released tag is a safe no-op - pipeline retries won't double-release
  or crash.
- **No output when there's nothing to do.** `semver-next` writes no file
  (and prints nothing) when no commit warrants a release - consumers key off
  file-presence, not a parsed exit code, to decide whether to release.

## Testing

Tests are [bats](https://github.com/bats-core/bats-core) specs that exercise
the real scripts against local, throwaway git repos - no network, no mocks
of git itself.

```sh
docker run --rm --entrypoint sh -v "$PWD":/code -w /code bats/bats:latest -c \
  'apk add --no-cache git bash >/dev/null && git config --global user.email t@e.com \
   && git config --global user.name T && bats test/'
```

Lint (shellcheck + shfmt) and tests both run in CI on every push and PR -
see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
