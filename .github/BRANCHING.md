# Branch flow

Permanent branches are **`main`**, **`stage`**, and **`develop`**. They are
protected by repository rules and the `branch-flow` workflow. Direct pushes,
force pushes, and deletion should remain disabled.

## Allowed merges

| Target | Allowed sources |
|---|---|
| `develop` | `feat/*`, `fix/*`, `docs/*`, `chore/*`, `refactor/*`, `test/*` |
| `stage` | `develop` |
| `main` | `stage`, `fix/*` for an emergency hotfix |

## Normal flow

1. Create a work branch from `develop`, such as `feat/<slug>`.
2. Open and merge a PR into `develop`.
3. Promote `develop` to `stage` by PR.
4. Validate staging and promote `stage` to `main` by PR.
5. Create release tags only from `main`.

Core-sync PRs created in wrapper repositories use
`chore/core-v<version> → develop`. They never bypass the promotion chain.
