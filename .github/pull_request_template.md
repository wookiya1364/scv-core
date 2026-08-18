## Summary

<!-- What changed and why, in 1–3 lines. -->

## Changes

-

## Tests

- [ ] `bash tests/run.sh`
- [ ] `bash core/tests/run-dry.sh`
- [ ] relevant focused regression updated

## DeckUI (if touched)

- [ ] `pnpm -C core/DeckUI typecheck`
- [ ] `pnpm -C core/DeckUI build:deck`

## Contract checklist

- [ ] Canonical `core/` remains host-neutral
- [ ] Core/profile/template version impact considered
- [ ] `CHANGELOG.md` and integration docs updated if behavior changed
- [ ] Branch follows [`.github/BRANCHING.md`](./BRANCHING.md)
- [ ] Code change adds its archived plan (`scv/archive/<slug>/PLAN.md`), or the title
      declares `[no-plan: <reason>]` — an empty `[no-plan]` is refused
- [ ] No secrets, dependency directories, caches, or generated build output
