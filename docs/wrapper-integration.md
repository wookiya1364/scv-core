# Wrapper integration

## 1. Define a host profile

Profiles are line-oriented data files. They are never sourced as shell code.
Both legacy state names should be listed during the cross-host transition.

```dotenv
SCV_HOST_PROFILE_API=1
SCV_HOST_ID=example-host
SCV_HOST_LABEL='Example Host'
SCV_ACTION_TEMPLATE='example:{action}'
SCV_ARGUMENT_STYLE=argv-array
SCV_STATE_INDEX=SCV.md
SCV_LEGACY_STATE_INDEXES='CLAUDE.md|CODEX.md'
SCV_ROOT_ENV=EXAMPLE_PLUGIN_ROOT
SCV_GRAPH_SKILL_PATHS='$HOME/.example/graph/SKILL.md'
SCV_UPDATE_OWNER=adapter
SCV_MODEL_POLICY_OWNER=adapter
```

Validate it before vendoring:

```bash
tools/validate-host-profile.sh --profile adapter/host-profile.env
```

The full field and safety contract is in
[`core/contracts/host-profile.md`](../core/contracts/host-profile.md).

## 2. Pin and materialize Core

For local development:

```bash
/path/to/scv-core/tools/vendor-core.sh \
  --source /path/to/scv-core \
  --target vendor/scv-core \
  --profile adapter/host-profile.env
```

For a release artifact, first verify its sidecar checksum, extract it to a
temporary directory, then pass the extracted top-level directory as `--source`
and the verified archive hash as `--artifact-sha256`.

Vendoring is staged and replaces the target only after verification succeeds.
The generated `core.lock.json` records:

| Field | Meaning |
|---|---|
| `core_version`, `core_api`, `template_version` | Pinned compatibility axes |
| `source_repository`, `source_commit` | Upstream identity |
| `source_manifest_sha256`, `source_payload_sha256` | Canonical release metadata |
| `manifest_sha256`, `payload_sha256` | Host-materialized projection metadata |
| `artifact_sha256` | Downloaded release archive hash, or `null` for local vendoring |
| `vendored_at` | Reproducible upstream source timestamp |

## 3. Generate the adapter projection

The wrapper exposes its runtime's native action-discovery files. Each generated
action delegates to the materialized Core protocol and entrypoint. Do not edit
vendored files manually; regenerate them from the pinned Core catalog.

The adapter must implement the `update` and `set-models` entrypoints and
runtime plugin metadata. State-index inspection and migration are not
adapter-owned: a wrapper may expose a thin shim, but it must delegate to the
materialized `core/scripts/state-index.sh`. Keep adapter-owned files outside
`vendor/scv-core`.

## 4. Migrate legacy Deck runtime

Before replacing a pre-0.20.2 Core payload, invoke the verified candidate
helper against the old DeckUI path:

```bash
SCV_DECK_CACHE_DIR=/optional/absolute/cache \
  /candidate/core/scripts/deck-runtime.sh migrate \
  --from /installed/legacy/DeckUI
```

Run this before the live Core swap. The operation is idempotent, leaves the
legacy tree intact, and fails on a destination collision. A failed wrapper
transaction may leave only the additive external cache; it must leave the
installed plugin unchanged.

Strict migration above is required when `/installed/legacy/DeckUI` belongs to
an existing vendor that may be removed after the swap. It verifies every
source/destination pair and prevents the wrapper from discarding that
ephemeral source's only runtime data.

Only a persistent legacy source may opt into authoritative cache reuse. The
accepted argument order is exact:

```bash
SCV_DECK_CACHE_DIR=/optional/absolute/cache \
  /candidate/core/scripts/deck-runtime.sh migrate \
  --from /persistent/legacy/DeckUI \
  --reuse-existing
```

Core preflights all eligible runtime entries. If any pre-existing destination
differs from its source, it treats the existing cache as authoritative and
skips the entire legacy source: no equal or missing destination is copied.
With no mismatch, the operation remains additive. Any collision that appears
after preflight fails closed rather than changing to reuse mode.

Claude's persistent live DeckUI and Codex's persistent plugin-root legacy
snapshot may use `--reuse-existing`. A Codex existing-vendor recovery snapshot
that can disappear after replacement must use the strict default.

## 5. Validate the wrapper

At minimum, wrapper CI should:

1. verify the pinned Core hashes and profile;
2. regenerate the projection and fail on a diff;
3. assert all 14 actions exist exactly once;
4. run Core's shared regression suite through the wrapper layout;
5. test adapter-owned update and model-policy behavior;
6. ensure installed runtime execution performs no Core network fetch.

## 6. Automated updates

Core releases send a `repository_dispatch` event named
`scv-core-released` with this payload:

```json
{
  "version": "0.21.0",
  "tag": "v0.21.0",
  "asset_url": "https://github.com/wookiya1364/scv-core/releases/download/v0.21.0/scv-core-v0.21.0.tar.gz",
  "checksum_url": "https://github.com/wookiya1364/scv-core/releases/download/v0.21.0/scv-core-v0.21.0.tar.gz.sha256"
}
```

The wrapper workflow downloads both immutable files, verifies SHA-256, vendors
with its profile, runs tests, then opens `chore/core-v<version>` against
`develop`. It must never update a permanent branch directly.
