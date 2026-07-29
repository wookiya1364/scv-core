# Architecture

SCV is split into one behavioral source of truth and thin host adapters.

```text
                         ┌──────────────────────┐
                         │       scv-core       │
                         │ protocols + scripts  │
                         │ template + DeckUI    │
                         │ contracts + tests    │
                         └──────────┬───────────┘
                                    │ pinned by tag
                                    │ checksummed tar.gz + SHA-256
                   ┌────────────────┴────────────────┐
                   │                                 │
        ┌──────────▼──────────┐           ┌──────────▼──────────┐
        │ scv-claude-code     │           │ scv-codex           │
        │ Claude adapter      │           │ Codex adapter       │
        │ pinned Core payload │           │ pinned Core payload │
        └─────────────────────┘           └─────────────────────┘
```

## Ownership boundary

Core owns behavior that must remain identical across hosts:

- the 14-action catalog and the 12 core-owned implementations;
- planning, work, reporting, regression, workspace, handoff, and Deck behavior;
- the hydrated `scv/` project layout and `SCV.md` state schema;
- shared migration and conflict-detection semantics;
- shared tests and DeckUI.

Adapters own behavior that cannot be host-neutral:

- plugin manifests and marketplace metadata;
- action discovery files and invocation syntax;
- translating host arguments into the Core entrypoint contract;
- installation/update mechanics;
- host model policy and model metadata;
- optional host state-pointer files and their explicit migration UX.

`update` and `set-models` remain in the shared action catalog so both products
present the same capability surface, but their entrypoints are adapter-owned.

## Build-time projection, local runtime

Core protocols contain only canonical tokens:

- `action:<id>` for action references;
- `{{SCV_ARGS}}` for host arguments;
- the profile root-variable token for installed-path references.

The wrapper validates its line-oriented profile and materializes those tokens
while vendoring a pinned release. The installed plugin runs entirely from the
vendored payload; it does not fetch Core at runtime.

## Immutable source, external Deck runtime

The vendored `core/DeckUI` tree is immutable source. `deck-runtime.sh` copies
that source into a user cache namespaced by `source_payload_sha256` before Deck
execution. Both wrappers therefore resolve the same Core release to the same
cache while their plugin trees remain verifiable and replaceable.

Only mutable runtime entries are migrated from a legacy in-plugin DeckUI:

- root and deckdoc `node_modules`;
- `dist-deck`;
- non-sample generated `src/deck/decks/<slug>/deck.json`.

Migration is additive and collision-safe. It never deletes the legacy source,
never follows generated-deck links, and never replaces a different cached
value.

Strict migration is the default. Before copying, Core preflights every eligible
legacy entry and its destination. A different pre-existing destination is a
collision; Core copies no legacy runtime entry, never overwrites the
destination, and leaves the source unchanged.

For a persistent legacy source, callers may explicitly select
`migrate --from LEGACY_DECKUI --reuse-existing`. If preflight finds even one
different pre-existing destination, the current cache becomes authoritative
for the whole migration and Core copies nothing from that legacy source,
including entries whose destinations are equal or missing. If preflight finds
no mismatch, the operation keeps the normal additive behavior. A collision
that appears after preflight always fails closed; it never switches a running
transaction into reuse mode.

This opt-in is safe only while the legacy source remains available after the
operation. Persistent Claude live DeckUI and Codex plugin-root legacy snapshots
may use it. Recovery from an existing vendor that a wrapper will remove after
a successful swap is ephemeral and must remain strict, otherwise an
authoritative-reuse decision could discard its only runtime data.

Every mutating cache operation is descriptor-relative. Core opens the cache
base from the filesystem root one component at a time with no-follow
semantics, then pins the payload namespace and runtime target by device,
inode, and type. Lock candidates, stale quarantine, staging, migration,
installation, and cleanup use only those descriptors and atomic no-replace
renames. If any visible ancestor, namespace, target, lock, or owner is replaced
mid-operation, Core fails closed and does not follow the replacement.

## State-index transition

`scv/SCV.md` is the only canonical state index. A profile may declare
`CLAUDE.md|CODEX.md` as legacy indexes. Resolution follows these rules:

1. Use `SCV.md` when it exists.
2. Otherwise, read a single non-pointer legacy index.
3. Treat the exact `SCV:HOST-POINTER` marker as an adapter pointer, not a second
   state copy.
4. If two independent indexes exist and differ byte-for-byte, report a
   conflict. Read-only help remains diagnostic; mutating sync exits before
   changing files.
5. Explicit migration creates `SCV.md` without deleting the legacy file and
   preserves lifecycle status, `PROJECT:LOCAL`, and workspace metadata.

Help never triggers sync or migration. Dry-run sync reports the pending
migration without modifying the working tree.

## Version axes

- `VERSION` tracks behavior and release payload changes.
- `CORE_API` changes only when wrapper integration becomes incompatible.
- `TEMPLATE_VERSION` tracks the hydrated project-template schema independently.

A wrapper may update Core without changing its adapter version, but every
published wrapper release must pin one exact Core version and record its
integrity metadata.
