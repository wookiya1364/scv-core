#!/usr/bin/env bash
f="$PWD/scv/gears/release-ci/$repo.cmds"; [ -f "$f" ] || { echo "명령 목록 없음: $f" >&2; exit 1; }
d="$(sed -n 's/^dir //p' "$f")"; L="${TMPDIR:-/tmp}/release-ci/$repo"; mkdir -p "$L"
cd "$d" || exit 1; n=0
grep -v -e '^dir ' -e '^$' "$f" | while IFS= read -r c; do
  n=$((n + 1)); r=fail; JOBS="$jobs" bash -c "$c" < /dev/null > "$L/$n.log" 2>&1 && r=ok
  printf '%s\t%s\t%s\t%s\n' local "$r" "$c" "$L/$n.log"
done
