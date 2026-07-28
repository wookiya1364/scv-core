#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
catalog = json.loads((root / "core/actions.json").read_text())
actions = catalog["actions"]
expected = {
    "help", "status", "promote", "work", "codegen", "deck", "update",
    "regression", "report", "sync", "install-deps", "workspace", "handoff",
    "set-models",
}
assert catalog["core_api"] == 1
assert len(actions) == 14
assert {a["id"] for a in actions} == expected
assert len({a["id"] for a in actions}) == 14

for action in actions:
    protocol = root / "core" / action["protocol"]
    assert protocol.is_file(), protocol
    if action["owner"] == "core":
        assert action["entrypoint"], action
        assert (root / "core" / action["entrypoint"]).is_file(), action
    else:
        assert action["id"] in {"update", "set-models"}, action
        assert action["entrypoint"] is None, action

assert not (root / "core/scripts/update.sh").exists()
assert not (root / "core/scripts/apply-model-policy.sh").exists()
print("action catalog: ok")
PY
