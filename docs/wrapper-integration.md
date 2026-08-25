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
3. assert all 15 actions exist exactly once;
4. run Core's shared regression suite through the wrapper layout;
5. test adapter-owned update and model-policy behavior;
6. ensure installed runtime execution performs no Core network fetch;
7. run Core's two pull-request gates against the vendored copy.

### Pull-request gates

Both gates ship in the pinned payload and run from the wrapper's branch-flow
workflow, one step each. They read the same four environment variables:

```yaml
- name: Provenance gate
  env:
    BASE_REF: ${{ github.base_ref }}
    HEAD_REF: ${{ github.head_ref }}
    PR_TITLE: ${{ github.event.pull_request.title }}
    BASE_SHA: ${{ github.event.pull_request.base.sha }}
  run: bash vendor/scv-core/core/scripts/check-provenance.sh
```

`check-provenance.sh` refuses a pull request that changes code without adding
`scv/archive/<slug>/PLAN.md`. `check-vendor-provenance.sh` refuses a pull
request that rewrites `vendor/scv-core/` at any depth on a branch that is not
the sync bot's — hand-vendoring and the bot's vendoring look identical afterwards, but
only the bot resolves the published artifact and records both hashes.

Both exempt the release chain (base `stage` or `main`) and the sync branch, and
both accept one declared exception in the title: `[no-plan: <reason>]` and
`[manual-vendor: <reason>]` respectively. An empty marker with no reason is
refused. Two optional knobs: `SCV_PROVENANCE_EXEMPT`, colon-separated extra
exempt path globs, and `SCV_VENDOR_SYNC_BRANCH`, the glob matching the bot's
branch (default `chore/core-*`).

The vendor gate matches by shape, not by a hardcoded path, so it works whether
the wrapper nests the tree at `vendor/scv-core/` or deeper.

## 6. Hook seam (journal capture, v0.22.0+)

Hook **registration is wrapper-owned**; Core ships only the executable
templates and this contract — the same ownership boundary as `update` and
`set-models`. The templates capture free conversation (turns that never invoke
an `action:*`) into the committed, author-attributed team journal
(`scv/journal/<YYYYMMDD>-<author>.md`).

| Template (materialized payload) | Host event | stdin contract |
|---|---|---|
| `core/template/hooks/on-user-prompt.sh` | Claude Code: `UserPromptSubmit` · Codex: the equivalent pre-turn / prompt-submitted hook | one JSON object with a `prompt` string field |
| `core/template/hooks/on-stop.sh` | Claude Code: `Stop` · Codex: the equivalent turn-end / session-end hook | one JSON object with a `transcript_path` field pointing at a JSONL transcript |

Wrapper requirements:

1. **Register** the two scripts for the events above (e.g. Claude Code
   `settings.json` → `hooks.UserPromptSubmit[].hooks[].command` and
   `hooks.Stop[].hooks[].command`), executing with the **project root as
   cwd** — the templates resolve `scv/` relative to cwd and no-op elsewhere.
2. **Export `SCV_CORE_ROOT`** (absolute path of the materialized `core/`) so
   the templates can locate `scripts/journal-append.sh`. Without it they fall
   back to their in-payload relative location
   (`<hook dir>/../../scripts/journal-append.sh`) — valid when the wrapper
   registers the vendored files in place, broken when it copies them
   elsewhere.
3. **Preserve the non-blocking guarantee.** The templates exit `0` on every
   failure (invalid JSON, missing `prompt`, unreadable/unknown transcript,
   missing `jq`/`python3`, un-hydrated project) and write nothing. A wrapper
   that wraps or copies them must not turn hook failure into a session
   failure, and must not register them as blocking hooks.
4. **Never bypass redaction.** All journal writes route through
   `journal-append.sh`, whose redaction filter
   (password/token/secret/api-key values, `Bearer` tokens, `AKIA…` keys →
   `[REDACTED]`) runs before anything hits disk. Wrappers must not write to
   `scv/journal/` directly.
5. Author attribution comes from `core/scripts/lib/author.sh`
   (`git config user.name` → `GIT_AUTHOR_NAME` → `USER` → `unknown`,
   filename-slugged). Wrappers needing a different identity source should
   export `GIT_AUTHOR_NAME` rather than patch the templates.
6. **Expect stdout on the prompt-submitted event (v0.31.0+).**
   `on-user-prompt.sh` prints to stdout in hydrated projects, and hosts that
   add this event's stdout to the model context — Claude Code and Codex both
   do — therefore deliver it on **every** turn, commands or not. Register the
   hook for that reason even where journaling alone did not justify it. Two
   blocks ship today, each with its own switch in `scv/scv_settings.json`
   (the project `.env` is not read, 0.32.0+):
   - the five-line plain-language *answer shape* reminder, unless
     `SCV_PLAIN_LANGUAGE=off` (absent / `on` / any other value = on);
     `SCV_PLAIN_MAX_SENTENCES=<n>` (positive integer) raises the first-answer
     sentence cap from 2 to n, anything else means 2;
   - the always-on routing block (0.35.0+), unless `SCV_ALWAYS_ON=off`: it
     instructs the model to route a free-conversation turn through the help
     action's Mode decision, and never to hijack a turn already running an
     SCV action.
   Neither block enters the journal, and the non-blocking guarantee is
   unchanged.

Hosts without hook support cannot capture free conversation — the session-end
protocol summaries partially compensate; the gap is documented in the
project-side `scv/journal/README.md`.

## 7. Register the workspace guard

`core/template/hooks/guard.sh` is a `PreToolUse` hook that denies writes no SCV
action accounts for: creating a plan file under `<scv_root>/promote/` without a
receipt (Rule A), and writing outside the workflow directory without a receipt
(Rule B). A receipt is minted when the host itself reports that an SCV action is
running — the model cannot fabricate a host event. The rules, the exempt set,
and the reasoning are in
[`core/contracts/guard.md`](../core/contracts/guard.md).

Registration is **wrapper-owned**, like the journal hooks above. The script
names no host and no tool — the only event name in it is the `PreToolUse` that
its denial JSON echoes back — and the wrapper tells it what kind of call this is
by setting `SCV_GUARD_MODE` on each hook entry.

| `SCV_GUARD_MODE` | Register on | Behavior |
|---|---|---|
| `mint` | the host event that reports an SCV action starting | records a receipt for this session and project; never denies |
| `gate-write` | editor-style write tools | reads the target path out of the payload; may deny |
| `gate-bash` | shell / command tools | mints when the command calls into `SCV_GUARD_SCRIPTS`; otherwise checks any patch target named inside the command; may deny |

`mint` takes the reported action id from `.tool_input.skill`, then
`.command_name`, then `.tool_input.command_name`, and mints when the id matches
the allowlist. A host may need more than one `mint` entry — scv-claude-code
registers one on `PreToolUse` with a `Skill` matcher and one on
`UserPromptExpansion`, since either can be the first event that names the
action. A host with no such event mints from `gate-bash` alone: scv-codex
registers no `mint` entry and relies on the action scripts being invoked through
its shell tool. On that arrangement, `SCV_GUARD_SCRIPTS` takes a colon-separated
list of directories, each matched as a fixed string — list both the vendored
Core scripts and the adapter's own script directory, or the adapter-owned
actions (`update`, `set-models`, and any Core action the adapter reroutes)
never mint. That is not hypothetical: scv-codex shipped with only the vendored
directory listed, and its four adapter-routed calls minted nothing — and still
do, until that wrapper's own follow-up release adopts the list form.
`core/contracts/guard.md` records the requirement. Entries must be absolute
paths with no ':' inside them and no surrounding whitespace; the guard drops
anything else instead of matching it.

Optional environment, all supplied by the wrapper:

| Variable | Meaning |
|---|---|
| `SCV_GUARD=off` | disable the guard entirely. Process environment only — never read from a file, or the agent could exempt itself in one line |
| `SCV_GUARD_STATE` | directory holding receipts; defaults to `${TMPDIR:-/tmp}/scv-guard` |
| `SCV_GUARD_ACTIONS` | regex of action ids the host may report in `mint` mode; defaults to the 15 shipped ids |
| `SCV_GUARD_SCRIPTS` | action-script directories, colon-separated absolute paths (no ':' in a path, no stray whitespace — invalid entries are dropped); a shell command containing any of them mints |
| `SCV_GUARD_EXEMPT` | colon-separated extra exempt paths, matched as globs relative to the project root. This is where the host's own config file goes — scv-claude-code passes `.claude/settings.json:.claude/settings.local.json`, scv-codex passes `.codex/config.toml` |
| `SCV_GUARD_RULE_B=off` | keep Rule A only |

Wrapper requirements:

1. **Point the command at a path the host actually provides.** This is the one
   failure that hides itself completely. If the root variable is wrong, the hook
   still fires, the shell finds no script, the host proceeds as it does for any
   missing hook, and nothing anywhere reports a problem — the guard is inert and
   the product looks healthy. scv-codex shipped that way in 0.25.0-codex.1: the
   entry named a plugin-root variable the host does not set. The fix was
   `${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}`. Confirm a real denial in a fresh
   session before believing the guard is on; a green build proves nothing here.
2. **Register it as a blocking hook** — the opposite of the journal templates. A
   denial is carried in the hook's own stdout
   (`hookSpecificOutput.permissionDecision = "deny"`), and the script exits `0`
   either way, so the host must be reading that output for the guard to have any
   effect at all.
3. **Keep the timeout short.** Both shipped wrappers use 5 seconds; the guard
   runs on every matched tool call.
4. **Do not turn failure into a denial.** The policy is fail **open**: an empty
   payload, or neither `jq` nor `python3` on the box, prints one line to stderr
   and allows. Only an explicit rule match denies.
   The hosts already proceed when a hook is missing or times out, so closing on
   internal error buys almost nothing against an adversary who simply deletes the
   script, while one guard bug would deny every write in every project at once.
   A wrapper that wraps the script must not convert its exit status into a block.
5. **Let it stay inert off-SCV.** The guard resolves the workflow root by walking
   up from the payload's `cwd` and allows immediately when there is none, so a
   globally registered entry does not affect projects that never adopted SCV.

Receipts are keyed by session and project together, so one earned in a checkout
does not unlock a different one. The session comes from `.session_id` in the
payload; a host that does not supply one shares a single `nosession` key.

## 8. Automated updates

Core releases send a `repository_dispatch` event named
`scv-core-released` with this payload:

```json
{
  "version": "0.24.0",
  "tag": "v0.24.0",
  "asset_url": "https://github.com/wookiya1364/scv-core/releases/download/v0.24.0/scv-core-v0.24.0.tar.gz",
  "checksum_url": "https://github.com/wookiya1364/scv-core/releases/download/v0.24.0/scv-core-v0.24.0.tar.gz.sha256"
}
```

The wrapper workflow downloads both immutable files, verifies SHA-256, vendors
with its profile, runs tests, then opens `chore/core-v<version>` against
`develop`. It must never update a permanent branch directly.
