#!/usr/bin/env bash
# on-stop.sh — host hook template (SCV Core, v0.22.0+).
#
# Purpose: when the host agent finishes responding (the stop / session-end hook
# event, e.g. the event named `Stop`), summarize the assistant's response into
# the committed team journal.
#
# Contract (see docs/wrapper-integration.md §6 "Hook seam" in scv-core):
#   - stdin carries ONE JSON object containing a `transcript_path` field — a
#     JSONL transcript file whose exact schema is host-version dependent.
#   - This template defensively extracts the latest assistant text blocks and
#     appends a bounded tail via journal-append.sh (redaction runs before any
#     write). Transcript formats it cannot parse are quietly skipped.
#   - Registration/installation is WRAPPER-OWNED — Core ships only this
#     template and the contract. The wrapper should export SCV_CORE_ROOT.
#
# NON-BLOCKING GUARANTEE: recording failure must never block a session — ANY
# failure (bad JSON, unreadable/unknown transcript, missing jq) → exit 0, no
# write. Wrappers copying this template must preserve that guarantee.
set -u

[[ -d scv ]] || exit 0

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>/dev/null && pwd )" || exit 0
JOURNAL_APPEND="${SCV_CORE_ROOT:-$SCRIPT_DIR/../..}/scripts/journal-append.sh"
[[ -f "$JOURNAL_APPEND" ]] || exit 0

INPUT="$(cat 2>/dev/null || true)"
[[ -n "$INPUT" ]] || exit 0

TRANSCRIPT=""
if command -v jq >/dev/null 2>&1; then
  TRANSCRIPT="$(printf '%s' "$INPUT" | jq -r 'try (.transcript_path // empty)' 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  TRANSCRIPT="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    p = d.get("transcript_path", "")
    sys.stdout.write(p if isinstance(p, str) else "")
except Exception:
    pass' 2>/dev/null || true)"
fi
[[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]] || exit 0

# Transcript scan needs jq's tolerant per-line parse (fromjson?). Without jq,
# skip quietly — journaling is best-effort by contract.
command -v jq >/dev/null 2>&1 || exit 0

SUMMARY="$(tail -n 200 "$TRANSCRIPT" 2>/dev/null \
  | jq -Rr 'fromjson? | select(.type? == "assistant")
            | (.message.content[]? | select(.type? == "text") | .text) // empty' 2>/dev/null \
  | tail -n 40 | tail -c 4000 || true)"
# The byte cap above can land inside a multibyte character (Korean, Japanese,
# emoji are 3–4 bytes each), leaving a broken lead byte at the head of the
# journal entry — and one invalid byte is enough to make an editor misread the
# whole file. Drop that partial sequence: iconv -c where available, python3
# as the fallback; with neither, the text is appended as-is (best effort).
# (GNU iconv -c exits 1 when it had to drop bytes — that is the success case
# here, so judge by output, not by exit code.)
_scv_clean=""
if command -v iconv >/dev/null 2>&1; then
  _scv_clean="$(printf '%s' "$SUMMARY" | iconv -c -f UTF-8 -t UTF-8 2>/dev/null || true)"
elif command -v python3 >/dev/null 2>&1; then
  _scv_clean="$(printf '%s' "$SUMMARY" | python3 -c 'import sys; sys.stdout.write(sys.stdin.buffer.read().decode("utf-8","ignore"))' 2>/dev/null || true)"
fi
[[ -n "${_scv_clean//[[:space:]]/}" ]] && SUMMARY="$_scv_clean"
[[ -n "${SUMMARY//[[:space:]]/}" ]] || exit 0

printf '%s\n' "$SUMMARY" | bash "$JOURNAL_APPEND" --speaker assistant >/dev/null 2>&1 || true
exit 0
