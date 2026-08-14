# Release and integrity

## Release checklist

1. Update `VERSION` using SemVer. Change `CORE_API` only for an incompatible
   wrapper contract and `TEMPLATE_VERSION` only for a template-schema change.
2. Update `CHANGELOG.md`.
3. Run:

   ```bash
   bash tests/run.sh
   bash core/tests/run-dry.sh
   for test_file in core/tests/test-*.sh; do bash "$test_file"; done
   pnpm -C core/DeckUI typecheck
   pnpm -C core/DeckUI build:deck
   tools/release-artifact.sh --output-dir dist
   ```

4. Merge the release-prep change into `develop` through a pull request.
5. Run the promote workflow. It does the rest — promotion, tag, and release:

   ```bash
   gh workflow run promote.yml
   ```

**Do not promote or tag by hand.** Steps 4 and 5 are the whole procedure, and the
workflow is what keeps them identical every time. It opens `develop → stage` and
`stage → main` as pull requests, waits for their checks, merges, then tags `main`
from `VERSION` and publishes the release. It never pushes to a permanent branch —
the branch ruleset requires a pull request for all three.

`workflow_dispatch` is its only trigger. Starting it is the human gate; nothing
promotes on a schedule or on push. A red check stops the chain and leaves that
pull request open, so a failed promotion is a pull request you can read, not a
half-finished merge.

The release workflow rejects a tag that does not exactly match `VERSION`, and the
promote workflow leaves an existing tag alone.

### The one thing that needs two runs

`workflow_dispatch` always executes the copy of the workflow file on the default
branch. So when the change you are promoting **edits `promote.yml` itself**, the
first run still uses the old file: it promotes your fix to `main` and may fail on
whatever the fix addresses. Run it a second time and the corrected file is the
one that executes.

This applies only to changes that touch the workflow file. Every other release is
one run.

## Artifacts

Version `X.Y.Z` publishes:

```text
scv-core-vX.Y.Z.tar.gz
scv-core-vX.Y.Z.tar.gz.sha256
```

The archive has one top-level directory named `scv-core-vX.Y.Z/`. File order,
mtime, owner, group, and gzip metadata are normalized so the same source commit
produces the same archive bytes.

Verify before extraction:

```bash
curl -fLO https://github.com/wookiya1364/scv-core/releases/download/vX.Y.Z/scv-core-vX.Y.Z.tar.gz
curl -fLO https://github.com/wookiya1364/scv-core/releases/download/vX.Y.Z/scv-core-vX.Y.Z.tar.gz.sha256
sha256sum -c scv-core-vX.Y.Z.tar.gz.sha256
```

On macOS, use `shasum -a 256 -c` for the sidecar.

## Integrity layers

The sidecar protects the downloaded archive. Inside the export:

- `SHA256SUMS` protects every distributable Core/tool file;
- `core-manifest.json` records the same files with byte sizes and hashes;
- `SOURCE_COMMIT`, `SOURCE_DATE`, and `SOURCE_INFO` identify provenance;
- wrapper `core.lock.json` records both canonical and materialized hashes.

Published exports and release archives contain only regular files and
directories. Source-checkout metadata links are materialized as regular files;
all remaining links and special files fail export. Dependency directories,
caches, build output, and temporary files are never released.

DeckUI runtime state is also never part of a release. At execution time Core
initializes a payload-keyed user cache atomically. Wrapper updates may migrate
the narrow legacy runtime inventory into that cache before replacing an old
payload. Cache mutation is anchored to verified open directory descriptors, so
replacing a visible cache ancestor, namespace, target, or lock during an
operation cannot redirect staging, installation, cleanup, or lock-owner
removal to an external path.

## Promote workflow options

```bash
gh workflow run promote.yml                       # promote, tag, release
gh workflow run promote.yml -f release=false      # promote only, no tag
gh workflow run promote.yml \
  -f notes_file=docs/releases/<version>.md        # hand-written notes
```

Without `notes_file` the release notes are generated from the commits.

The workflow takes no version argument. The tag always comes from whatever
`VERSION` holds on `main`, so there is nothing to keep in sync by hand — bumping
`VERSION` in step 1 is what selects the release number.

Run it from the Actions tab if you prefer a button.

### When it fails

Read which step failed.

**"Promote develop to stage, then stage to main" failed** — a check went red on
one of the two pull requests, or the pull request never became mergeable within
fifteen minutes. Either way the pull request is still open and nothing is left
half-promoted; fix the branch and run the workflow again. It reuses the open
pull request rather than opening a second one.

The step waits on GitHub's own `mergeStateStatus`, not on a count of checks.
Counting was wrong twice: a matrix job skipped by a path filter is reported
under its unexpanded name before the real jobs exist, so the count reached one
immediately and the merge was attempted against required checks that had not
started. `tests/test-promote-wait.sh` replays that exact rollup against the live
workflow block.

**The workflow ran the old logic** — `workflow_dispatch` executes the default
branch's copy of the file. A fix to `promote.yml` takes effect on the release
*after* the one that ships it.

**"Tag main and publish the release" failed** — promotion already succeeded, so
`main` carries the new `VERSION` and only the tag is missing. Fix the cause and
run again; the promotion steps will find nothing to do and skip straight to
tagging.

## Wrapper dispatch

The repository secret `SCV_WRAPPER_SYNC_TOKEN` sends an immediate
`repository_dispatch` event to both wrapper repositories. Each wrapper gets its
own attempt with three backoff retries, so one unreachable wrapper never costs
the other its notification.

Dispatch never blocks publishing: the release assets are uploaded by an earlier
step and stay intact. It does, however, **fail the release run** when either
wrapper was not notified — including when the secret is missing entirely. A
release that published cleanly but reached nobody is otherwise
indistinguishable from a healthy one, and that state persisted here unnoticed
until 2026-08-11. The job summary carries the exact re-send command.

Wrapper scheduled polling is the baseline fallback and does not require this
cross-repository secret. Both wrappers poll daily, resolve the latest immutable
Core release, and open the same update PR when the pinned version is behind — so
a red dispatch step delays propagation by up to a day rather than losing it.

Each wrapper owns the resulting update PR and its adapter tests. A failed
wrapper update does not mutate its pinned release.

## Do not vendor Core by hand

The bot's pull request is how a new pin lands. Wait for it, merge it, and bump
the wrapper version in a **separate** change afterwards.

Vendoring by hand is tempting during a release, because the version bump is
already open in front of you and copying the tree into that same branch looks
like it saves a round trip. It does not save anything. The bot's pull request
then arrives already satisfied and gets closed as redundant — 0.25.0 and 0.26.0
both ended that way — and the two paths are not equivalent: the bot resolves the
published release artifact and records the canonical and materialized hashes,
while a hand copy records whatever the working tree held at the time. Afterwards
nothing distinguishes them.

`check-vendor-provenance.sh` enforces this at merge time. It denies any pull
request that touches `*/vendor/scv-core/` unless the branch is the bot's, the
pull request is part of the release chain, or the title carries
`[manual-vendor: <reason>]` — the same shape as `[no-plan: <reason>]`.

Hand-vendoring stays available, because a Core contract change can genuinely
outrun the bot. It just has to be declared.
