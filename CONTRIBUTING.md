# Contributing

## Layout

- `bin/<name>` - the executable script, no file extension, `chmod +x`.
- `test/<name>.bats` - [bats](https://github.com/bats-core/bats-core) tests
  for that script.
- `docs/<name>.md` - usage docs for that script, linked from the README.

## Conventions

- Scripts are plain `bash` (`#!/usr/bin/env bash`, `set -euo pipefail`), no
  other language runtime. Keep it that way - the entire point of this
  project is having nothing to `npm install`.
- Diagnostics (`log_info`/`log_err`) go to **stderr**. Stdout is reserved for
  machine-readable output (a version number, etc.) so scripts compose in
  pipelines and CI.
- Exit codes: `0` success, `1` the tool ran but found a failure (lint
  failure, release step failure), `2` usage error (bad arguments).
- Nothing reads GitLab/GitHub-specific environment variables directly -
  platform values come in as CLI flags. Translating `CI_*`/`GITHUB_*` vars
  into flags is the job of the CI wrapper (e.g. `action.yml`), not the
  script.
- Add a `-h`/`--help` block as a leading comment (the scripts `sed` their own
  header to print it) and keep it in sync with `docs/<name>.md`.

## Running tests and lint locally

No local toolchain install is required or expected - everything runs via
Docker:

```sh
# tests (bats/bats's image has no git, so install it first)
docker run --rm --entrypoint sh -v "$PWD":/code -w /code bats/bats:latest -c \
  'apk add --no-cache git bash >/dev/null && git config --global user.email t@e.com \
   && git config --global user.name T && bats test/'

# shellcheck
docker run --rm -v "$PWD":/code -w /code koalaman/shellcheck:stable bin/* test/*.bats

# shfmt (check formatting; drop -d to auto-format)
docker run --rm -v "$PWD":/code -w /code mvdan/shfmt:latest -i 0 -ci -d bin/*
```

## Pull requests

- One logical change per PR.
- Add or update bats tests for any behavior change.
- This repo dogfoods itself for versioning: commit subjects should follow
  Conventional Commits (`feat: ...`, `fix: ...`, etc.) since merges to `main`
  drive the next release.
