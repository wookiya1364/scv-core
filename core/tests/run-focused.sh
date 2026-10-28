#!/usr/bin/env bash
# run-focused.sh — 집중 시험(core/tests/test-*.sh)을 한 작업 안에서 동시에 돌린다.
#
# 시험 64개를 하나씩 돌리면 CI 집중 시험 단계가 10분을 넘는다. 시험은 서로 독립이므로
# 코어 수만큼 겹쳐 돌리고, 시간 한도를 재는 시험만 다른 시험이 다 끝난 뒤 하나씩 돌린다.
# 혼자 돌아야 하는 시험은 파일 앞 30줄 안에 다음 한 줄로 스스로 밝힌다:
#
#   # scv-test: serial
#
# 쓰는 법:
#   bash core/tests/run-focused.sh [--jobs N] [--dir DIR]
#     --jobs N   동시에 돌 시험 수(기본: SCV_TEST_JOBS, 없으면 이 컴퓨터의 코어 수)
#     --dir DIR  시험 폴더(기본: 이 파일이 있는 폴더)
#
# 출력: 시험마다 'PASS|FAIL  <초>s  <이름>' 한 줄(오래 걸린 순), 실패한 시험의 로그 전문,
# 마지막 줄 'run-focused: pass=N fail=N jobs=N wall=Ns'. 하나라도 실패하면 종료 코드 1.
# GitHub Actions 에서는 시험마다 로그를 접힌 묶음으로 함께 찍는다.
#
# 파이프라인: list_tests → classify → run_batch → summarize → report
#   (classify · summarize 는 문자열만 받고 돌려주는 순수 함수다.)

set -u

# ── 순수: 목록 줄 'path<TAB>mark' → 'parallel|serial<TAB>path'
rf_classify() {
  local path mark
  while IFS="$(printf '\t')" read -r path mark; do
    [[ -n "$path" ]] || continue
    if [[ "$mark" == "serial" ]]; then
      printf 'serial\t%s\n' "$path"
    else
      printf 'parallel\t%s\n' "$path"
    fi
  done
}

# ── 순수: 결과 줄 'name<TAB>rc<TAB>seconds' → 표 줄 · FAILED 줄 · TOTAL 줄
rf_summarize() {
  local rows name rc secs pass=0 fail=0 failed=""
  rows="$(cat)"
  while IFS="$(printf '\t')" read -r name rc secs; do
    [[ -n "$name" ]] || continue
    if [[ "$rc" == "0" ]]; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      failed="${failed}$(printf 'FAILED\t%s' "$name")"$'\n'
    fi
  done <<EOF
$rows
EOF
  printf '%s\n' "$rows" | awk -F'\t' 'NF >= 3 { printf "%s\t%s\t%s\n", $3, ($2 == "0" ? "PASS" : "FAIL"), $1 }' \
    | LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k3,3 \
    | awk -F'\t' '{ printf "ROW\t%s\t%s\t%s\n", $2, $1, $3 }'
  printf '%s' "$failed"
  printf 'TOTAL\t%s\t%s\n' "$pass" "$fail"
}

# ── 입구: 시험 폴더 → 'path<TAB>mark' (이름순)
rf_list_tests() {
  local dir="$1" f mark
  for f in "$dir"/test-*.sh; do
    [[ -f "$f" ]] || continue
    mark=""
    head -n 30 "$f" | grep -Eq '^# scv-test: serial([[:space:]]|$)' && mark="serial"
    printf '%s\t%s\n' "$f" "$mark"
  done | LC_ALL=C sort
}

# ── 부수효과: 시험 하나를 돌려 로그와 결과 줄을 남긴다
rf_run_one() {
  local logdir="$1" path="$2" name t0 t1 rc
  name="$(basename "$path" .sh)"
  t0=$(date +%s)
  bash "$path" > "$logdir/$name.log" 2>&1 < /dev/null
  rc=$?
  t1=$(date +%s)
  printf '%s\t%s\t%s\n' "$name" "$rc" "$((t1 - t0))" > "$logdir/$name.result"
}

# ── 부수효과: 동시에 돌 시험은 jobs 만큼 겹쳐, 혼자 돌 시험은 그 뒤 하나씩
rf_run_batch() {
  local self="$1" logdir="$2" jobs="$3" classified="$4" path
  printf '%s\n' "$classified" | awk -F'\t' '$1 == "parallel" { print $2 }' \
    | tr '\n' '\0' | xargs -0 -n 1 -P "$jobs" bash "$self" --one "$logdir"
  while IFS= read -r path; do
    [[ -n "$path" ]] && rf_run_one "$logdir" "$path"
  done <<EOF
$(printf '%s\n' "$classified" | awk -F'\t' '$1 == "serial" { print $2 }')
EOF
  cat "$logdir"/*.result 2>/dev/null
}

# ── 출구: 표 · 실패 로그 · 마지막 줄, 종료 코드
rf_report() {
  local summary="$1" logdir="$2" jobs="$3" wall="$4" ci="${GITHUB_ACTIONS:-}" f name pass fail
  if [[ "$ci" == "true" ]]; then
    for f in "$logdir"/*.log; do
      [[ -f "$f" ]] || continue
      echo "::group::$(basename "$f" .log)"
      cat "$f"
      echo "::endgroup::"
    done
  fi
  printf '%s\n' "$summary" | awk -F'\t' '$1 == "ROW" { printf "%s  %4ss  %s\n", $2, $3, $4 }'
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    echo
    echo "──── FAIL $name ── 로그 전문 ────"
    cat "$logdir/$name.log"
  done <<EOF
$(printf '%s\n' "$summary" | awk -F'\t' '$1 == "FAILED" { print $2 }')
EOF
  pass="$(printf '%s\n' "$summary" | awk -F'\t' '$1 == "TOTAL" { print $2 }')"
  fail="$(printf '%s\n' "$summary" | awk -F'\t' '$1 == "TOTAL" { print $3 }')"
  echo "run-focused: pass=${pass:-0} fail=${fail:-0} jobs=$jobs wall=${wall}s"
  [[ "${fail:-0}" == "0" && "${pass:-0}" != "0" ]]
}

rf_default_jobs() {
  local n="${SCV_TEST_JOBS:-}"
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || n="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || n=2
  printf '%s\n' "$n"
}

rf_main() {
  local self dir jobs t0 classified results summary
  self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  dir="$(dirname "$self")"
  jobs="$(rf_default_jobs)"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --jobs) jobs="${2:-}"; shift 2 ;;
      --dir) dir="${2:-}"; shift 2 ;;
      *) echo "run-focused: unknown argument: $1" >&2; return 2 ;;
    esac
  done
  [[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo "run-focused: --jobs needs a positive number" >&2; return 2; }
  [[ -d "$dir" ]] || { echo "run-focused: no such directory: $dir" >&2; return 2; }

  RF_LOGDIR="$(mktemp -d "${TMPDIR:-/tmp}/scv-focused.XXXXXX")"
  trap 'rm -rf "$RF_LOGDIR"' EXIT
  t0=$(date +%s)
  classified="$(rf_list_tests "$dir" | rf_classify)"
  results="$(rf_run_batch "$self" "$RF_LOGDIR" "$jobs" "$classified")"
  summary="$(printf '%s\n' "$results" | rf_summarize)"
  rf_report "$summary" "$RF_LOGDIR" "$jobs" "$(( $(date +%s) - t0 ))"
}

if [[ "${1:-}" == "--one" ]]; then
  rf_run_one "$2" "$3"
  exit 0
fi
if [[ "${BASH_SOURCE[0]:-}" == "$0" ]]; then
  rf_main "$@"
fi
