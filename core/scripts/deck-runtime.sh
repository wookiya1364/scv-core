#!/usr/bin/env bash
# Resolve and maintain DeckUI's mutable runtime outside the immutable Core tree.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SOURCE_DECKUI="$CORE_DIR/DeckUI"
COMMAND="${1:-}"
LEGACY_ROOT=

usage() {
  cat <<'EOF' >&2
Usage:
  deck-runtime.sh path
  deck-runtime.sh ensure
  deck-runtime.sh migrate --from LEGACY_DECKUI

SCV_DECK_CACHE_DIR overrides the cache base. The selected cache is always
namespaced by the canonical Core source-payload SHA-256.
EOF
}

case "$COMMAND" in
  path|ensure)
    [[ $# -eq 1 ]] || { usage; exit 2; }
    ;;
  migrate)
    [[ $# -eq 3 && "$2" == "--from" ]] || { usage; exit 2; }
    LEGACY_ROOT="$3"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ -n "${SCV_DECK_CACHE_DIR:-}" ]]; then
  CACHE_BASE="$SCV_DECK_CACHE_DIR"
elif [[ -n "${XDG_CACHE_HOME:-}" ]]; then
  CACHE_BASE="$XDG_CACHE_HOME/scv/deckui"
elif [[ -n "${HOME:-}" ]]; then
  CACHE_BASE="$HOME/.cache/scv/deckui"
else
  echo "ERROR: set SCV_DECK_CACHE_DIR, XDG_CACHE_HOME, or HOME" >&2
  exit 1
fi

python3 - \
  "$COMMAND" "$SOURCE_DECKUI" "$CORE_DIR" "$CACHE_BASE" "$LEGACY_ROOT" <<'PY'
from __future__ import annotations

import contextlib
import hashlib
import json
import os
import shutil
import stat
import sys
import tempfile
import time
import uuid
from pathlib import Path

command, source_arg, core_arg, base_arg, legacy_arg = sys.argv[1:]
source = Path(source_arg)
core = Path(core_arg)
raw_base = Path(base_arg).expanduser()

RUNTIME_DIR_NAMES = {
    "node_modules",
    "dist",
    "dist-deck",
    ".vite",
    ".cache",
    "coverage",
}
MANAGED_DECKS = {"demo-prd", "refund"}


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"ERROR: {message}")


def is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_payload_key() -> str:
    candidates = (
        core / "core.lock",
        core / "core.lock.json",
        core.parent / "core.lock",
        core.parent / "core.lock.json",
    )
    for candidate in candidates:
        if not candidate.exists() and not candidate.is_symlink():
            continue
        if candidate.is_symlink() or not candidate.is_file():
            fail(f"Core lock is unsafe: {candidate}")
        try:
            value = json.loads(candidate.read_text(encoding="utf-8")).get(
                "source_payload_sha256"
            )
        except (OSError, json.JSONDecodeError) as error:
            fail(f"Core lock is invalid: {candidate}: {error}")
        if not (
            isinstance(value, str)
            and len(value) == 64
            and all(character in "0123456789abcdef" for character in value)
        ):
            fail(f"Core lock has no valid source_payload_sha256: {candidate}")
        return value

    # Source checkouts have no generated core.lock. Hash only immutable DeckUI
    # inputs, pruning every runtime directory and non-sample generated deck.
    digest = hashlib.sha256()
    for current, directories, files in os.walk(source, topdown=True):
        current_path = Path(current)
        kept_directories: list[str] = []
        for name in sorted(directories):
            if name in RUNTIME_DIR_NAMES:
                continue
            path = current_path / name
            entry = path.lstat()
            if not stat.S_ISDIR(entry.st_mode):
                fail(f"immutable DeckUI source contains a link or special file: {path}")
            relative = path.relative_to(source)
            digest.update(b"D\0" + relative.as_posix().encode() + b"\0")
            kept_directories.append(name)
        directories[:] = kept_directories
        for name in sorted(files):
            if name in RUNTIME_DIR_NAMES:
                continue
            path = current_path / name
            relative = path.relative_to(source)
            if (
                len(relative.parts) == 5
                and relative.parts[:3] == ("src", "deck", "decks")
                and relative.parts[-1] == "deck.json"
                and relative.parts[-2] not in MANAGED_DECKS
            ):
                continue
            entry = path.lstat()
            if not stat.S_ISREG(entry.st_mode):
                fail(f"immutable DeckUI source contains a link or special file: {path}")
            encoded = relative.as_posix().encode()
            digest.update(encoded + b"\0" + path.read_bytes() + b"\0")
    return digest.hexdigest()


if not source.is_dir() or source.is_symlink():
    fail(f"immutable DeckUI source is missing or unsafe: {source}")
source = source.resolve()

if not raw_base.is_absolute():
    fail("SCV Deck cache base must be an absolute path")
if raw_base.is_symlink():
    fail(f"SCV Deck cache base must not be a symlink: {raw_base}")
base = raw_base.resolve(strict=False)
home = Path(os.environ["HOME"]).resolve() if os.environ.get("HOME") else None
if base == Path(base.anchor) or (home is not None and base == home):
    fail(f"SCV Deck cache base is too broad: {base}")
if is_relative_to(base, source) or is_relative_to(source, base):
    fail("SCV Deck cache must be outside the immutable DeckUI source")

key = source_payload_key()
namespace = base / key
target = namespace / "DeckUI"
marker_name = ".scv-deck-runtime.json"
marker = target / marker_name


def validate_target() -> bool:
    if target.is_symlink():
        fail(f"SCV Deck runtime target must not be a symlink: {target}")
    if not target.exists():
        return False
    if not target.is_dir():
        fail(f"SCV Deck runtime target is not a directory: {target}")
    if marker.is_symlink() or not marker.is_file():
        fail(f"SCV Deck runtime marker is missing or unsafe: {marker}")
    try:
        metadata = json.loads(marker.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"SCV Deck runtime marker is invalid: {error}")
    if metadata.get("source_payload_sha256") != key:
        fail("SCV Deck runtime marker does not match the selected Core payload")
    return True


def process_is_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


@contextlib.contextmanager
def runtime_lock():
    base.mkdir(parents=True, exist_ok=True)
    if base.is_symlink() or not base.is_dir():
        fail(f"SCV Deck cache base is unsafe: {base}")
    namespace.mkdir(mode=0o700, exist_ok=True)
    if namespace.is_symlink() or not namespace.is_dir():
        fail(f"SCV Deck cache namespace is unsafe: {namespace}")

    lock = base / f".{key}.lock"
    token = uuid.uuid4().hex
    deadline = time.monotonic() + 30
    acquired = False
    while time.monotonic() < deadline:
        try:
            lock.mkdir(mode=0o700)
            (lock / "owner.json").write_text(
                json.dumps({"pid": os.getpid(), "token": token}) + "\n",
                encoding="utf-8",
            )
            acquired = True
            break
        except FileExistsError:
            if lock.is_symlink() or not lock.is_dir():
                fail(f"SCV Deck runtime lock is unsafe: {lock}")
            owner = lock / "owner.json"
            try:
                data = json.loads(owner.read_text(encoding="utf-8"))
                pid = int(data["pid"])
            except (OSError, ValueError, KeyError, json.JSONDecodeError):
                # A creator may be between mkdir and owner write.
                if time.time() - lock.stat().st_mtime < 5:
                    time.sleep(0.05)
                    continue
                pid = -1
            if pid > 0 and process_is_alive(pid):
                time.sleep(0.05)
                continue
            quarantine = base / f".{key}.stale-{uuid.uuid4().hex}"
            try:
                os.rename(lock, quarantine)
            except (FileNotFoundError, OSError):
                time.sleep(0.05)
                continue
            shutil.rmtree(quarantine)
    if not acquired:
        fail("timed out waiting for the SCV Deck runtime lock")

    try:
        yield
    finally:
        owner = lock / "owner.json"
        try:
            data = json.loads(owner.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            data = {}
        if data.get("token") != token:
            fail(f"SCV Deck runtime lock ownership changed: {lock}")
        owner.unlink()
        lock.rmdir()


def source_ignore(directory: str, names: list[str]) -> set[str]:
    current = Path(directory)
    ignored = {name for name in names if name in RUNTIME_DIR_NAMES}
    try:
        relative = current.relative_to(source)
    except ValueError:
        return ignored
    if (
        len(relative.parts) == 4
        and relative.parts[:3] == ("src", "deck", "decks")
        and relative.parts[-1] not in MANAGED_DECKS
        and "deck.json" in names
    ):
        ignored.add("deck.json")
    return ignored


def ensure_locked() -> None:
    if validate_target():
        return
    staged_parent = Path(
        tempfile.mkdtemp(prefix=".DeckUI.stage-", dir=str(namespace))
    )
    staged = staged_parent / "DeckUI"
    try:
        shutil.copytree(
            source,
            staged,
            symlinks=True,
            copy_function=shutil.copy2,
            ignore=source_ignore,
        )
        (staged / marker_name).write_text(
            json.dumps(
                {
                    "schema_version": 1,
                    "source_payload_sha256": key,
                    "source": str(source),
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        if target.exists() or target.is_symlink():
            if not validate_target():
                fail(f"SCV Deck runtime target appeared during initialization: {target}")
        else:
            os.rename(staged, target)
    finally:
        if staged_parent.exists():
            shutil.rmtree(staged_parent)


def entry_digest(path: Path) -> str:
    digest = hashlib.sha256()
    if path.is_symlink():
        digest.update(b"L\0" + os.fsencode(os.readlink(path)))
        return digest.hexdigest()
    if path.is_file():
        entry = path.lstat()
        digest.update(
            b"F\0"
            + str(stat.S_IMODE(entry.st_mode)).encode()
            + b"\0"
            + path.read_bytes()
        )
        return digest.hexdigest()
    if not path.is_dir():
        fail(f"legacy Deck runtime contains a special file: {path}")
    for current, directories, files in os.walk(path, topdown=True, followlinks=False):
        current_path = Path(current)
        for name in sorted(directories):
            child = current_path / name
            relative = child.relative_to(path).as_posix().encode()
            if child.is_symlink():
                digest.update(b"L\0" + relative + b"\0" + os.fsencode(os.readlink(child)))
            else:
                digest.update(b"D\0" + relative + b"\0")
        directories[:] = [
            name for name in directories if not (current_path / name).is_symlink()
        ]
        for name in sorted(files):
            child = current_path / name
            relative = child.relative_to(path).as_posix().encode()
            if child.is_symlink():
                digest.update(b"L\0" + relative + b"\0" + os.fsencode(os.readlink(child)))
            elif child.is_file():
                entry = child.lstat()
                digest.update(
                    b"F\0"
                    + relative
                    + b"\0"
                    + str(stat.S_IMODE(entry.st_mode)).encode()
                    + b"\0"
                    + child.read_bytes()
                )
            else:
                fail(f"legacy Deck runtime contains a special file: {child}")
    return digest.hexdigest()


def copy_runtime_entry(source_entry: Path, destination: Path) -> None:
    if destination.exists() or destination.is_symlink():
        if entry_digest(source_entry) != entry_digest(destination):
            fail(f"Deck runtime migration collision: {destination}")
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source_entry.is_dir() and not source_entry.is_symlink():
        staged_parent = Path(
            tempfile.mkdtemp(prefix=f".{destination.name}.stage-", dir=destination.parent)
        )
        staged = staged_parent / destination.name
        try:
            shutil.copytree(source_entry, staged, symlinks=True, copy_function=shutil.copy2)
            os.rename(staged, destination)
        finally:
            if staged_parent.exists():
                shutil.rmtree(staged_parent)
    elif source_entry.is_file() or source_entry.is_symlink():
        descriptor, staged_name = tempfile.mkstemp(
            prefix=f".{destination.name}.stage-", dir=destination.parent
        )
        os.close(descriptor)
        staged = Path(staged_name)
        staged.unlink()
        try:
            if source_entry.is_symlink():
                staged.symlink_to(os.readlink(source_entry))
            else:
                shutil.copy2(source_entry, staged)
            os.rename(staged, destination)
        finally:
            if staged.exists() or staged.is_symlink():
                staged.unlink()
    else:
        fail(f"legacy Deck runtime contains a special file: {source_entry}")


def migrate_locked(legacy_arg: str) -> None:
    legacy_raw = Path(legacy_arg).expanduser()
    if legacy_raw.is_symlink() or not legacy_raw.is_dir():
        fail(f"legacy DeckUI path is missing or unsafe: {legacy_raw}")
    legacy = legacy_raw.resolve()
    if legacy == target.resolve():
        return

    entries: list[tuple[Path, Path]] = []
    for relative in (
        Path("node_modules"),
        Path("scripts/deckdoc/node_modules"),
        Path("dist-deck"),
    ):
        source_entry = legacy / relative
        if source_entry.exists() or source_entry.is_symlink():
            entries.append((source_entry, target / relative))
    decks = legacy / "src/deck/decks"
    if decks.is_dir() and not decks.is_symlink():
        for deck_directory in sorted(decks.iterdir()):
            if deck_directory.is_symlink():
                fail(f"legacy generated Deck directory is a symlink: {deck_directory}")
            if not deck_directory.is_dir():
                continue
            generated = deck_directory / "deck.json"
            if not generated.exists() and not generated.is_symlink():
                continue
            if generated.is_symlink() or not generated.is_file():
                fail(f"legacy generated Deck file is unsafe: {generated}")
            if deck_directory.name not in MANAGED_DECKS:
                entries.append(
                    (
                        generated,
                        target / "src/deck/decks" / deck_directory.name / "deck.json",
                    )
                )

    # Compare every collision before copying anything.
    for source_entry, destination in entries:
        if destination.exists() or destination.is_symlink():
            if entry_digest(source_entry) != entry_digest(destination):
                fail(f"Deck runtime migration collision: {destination}")
    for source_entry, destination in entries:
        copy_runtime_entry(source_entry, destination)


if command == "path":
    print(target)
elif command == "ensure":
    with runtime_lock():
        ensure_locked()
    print(target)
else:
    with runtime_lock():
        ensure_locked()
        migrate_locked(legacy_arg)
    print(target)
PY
