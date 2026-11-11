#!/usr/bin/env bash
# pure-bench.sh — 순수함수(와 셸에서 띄우는 명령 하나)의 시간 · 메모리 · GPU · 부른 횟수를 잰다.
# 계약 contracts/composition.md · 계획 20261111-wookiya1364-pure-bench-and-gate.
#
# 판단은 lib/pure-bench.sh 의 순수 함수가 하고, 여기는 사전 읽기 · 실행 · 쓰기만 한다.
#
# Usage:
#   pure-bench.sh targets [--catalog DIR] [--only NAME]…
#       사전에서 잴 목록을 낸다: "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림(1/0)".
#       1배 = 예시를 25번 되풀이, 4배 = 100번. 늘릴 값이 없는 예시는 늘림 0 (늘려 재지 못함).
#
#   pure-bench.sh env
#       재는 환경 한 줄: 셸 버전 · 지역 설정 · GPU 읽는 도구.
#   pure-bench.sh run [--no-count] -- <명령…>
#       셸에서 띄우는 명령 하나를 감싸 잰다. 한 줄: "벽시계 초<탭>CPU 초<탭>메모리 MB<탭>GPU 사용률 %<탭>GPU 메모리 MB<탭>부른 횟수<탭>판정 잣대<탭>명령의 종료 코드".
#       판정 잣대: cpu(CPU 시간으로 본다) · wall-gpu(GPU 를 썼다 — 벽시계와 GPU 값으로 본다) · unmeasured(재지 못함).
#       잴 수 없는 값은 "-" (통과가 아니라 '재지 못함'). GPU 값은 컴퓨터 전체의 값이다.
#   pure-bench.sh fn [--catalog DIR] [--base DIR] [--only NAME]… [--scale 1|4]
#       사전의 함수를 그 예시(1배 또는 4배 입력)로 재서 줄마다:
#       "함수<탭>배<탭>되풀이<탭>회당 ms<탭>벽시계 초<탭>메모리 MB<탭>GPU 사용률<탭>GPU 메모리<탭>부른 횟수<탭>상태<탭>판정 잣대".
#       상태: ok · not-scalable(늘려 재지 못함) · load-failed(함수를 불러오지 못함) · not-shell(셸 함수가 아님).
#
#   pure-bench.sh composed [--catalog DIR] [--base DIR]
#       엮은 함수(다른 사전 함수를 2개 이상 부르는 사전 함수)를 "함수<탭>부르는 함수들" 줄로 낸다.
#   pure-bench.sh bench [--catalog DIR] [--base DIR] [--only NAME]… [--composed] [--tsv FILE]
#       함수를 1배 · 4배 입력으로 재서 표를 낸다(비고 · 끝의 셈 포함). --composed 는 엮은 함수와 그것이 부르는 함수만
#       재고, 엮은 함수의 표(묶음 전체의 값 · 부품 값의 합)를 덧붙인다. --tsv 는 표의 줄을 파일에도 쓴다.
#
# 환경: SCV_PB_GPU_TOOL=none|ioreg|nvidia 로 GPU 읽는 도구를 정한다(기본: 있는 것을 찾는다).
# 잰 값은 이 스크립트를 돌린 셸과 지역 설정의 값이다 — 같은 함수가 bash 3.2 와 bash 5 에서 열 배 넘게 다를 수 있다
# (2026-11-11: 낱말 나누기 한 번에 22ms 대 1.8ms). 앞뒤를 견줄 때는 같은 셸로 잰다. `env` 로 그 셸을 본다.
# Exit: 0 통과 · 2 사용법 오류
set -uo pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CORE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
# shellcheck source=lib/pure-catalog.sh
source "$SCRIPT_DIR/lib/pure-catalog.sh"
# shellcheck source=lib/pure-bench.sh
source "$SCRIPT_DIR/lib/pure-bench.sh"

# @effect read_catalog
# 이유: 사전 파일을 읽는다 — 파이프라인의 입구(차례 파일은 뺀다)
read_catalog() {
  local f
  for f in "$1"/*.md; do
    [[ -f "$f" && "${f##*/}" != INDEX.md ]] && cat "$f"
  done
  return 0
}

PB_TMP="$(mktemp -d "${TMPDIR:-/tmp}/scv-pure-bench.XXXXXX")" || exit 2
PB_SAMPLER=""
# @effect pb_cleanup
# 이유: 끝날 때 GPU 표본기를 끄고 임시 폴더를 지운다 — 남은 과정이 컴퓨터를 붐비게 하지 않게
pb_cleanup() {
  [[ -z "$PB_SAMPLER" ]] || { kill "$PB_SAMPLER" 2>/dev/null; wait "$PB_SAMPLER" 2>/dev/null; }
  rm -rf "$PB_TMP"
}
trap pb_cleanup EXIT

# @effect pb_gpu_tool
# 이유: 이 컴퓨터에서 GPU 를 읽을 도구를 찾는다(환경 값이 있으면 그것) — ioreg | nvidia | none
pb_gpu_tool() {
  case "${SCV_PB_GPU_TOOL:-}" in ioreg|nvidia|none) printf '%s' "$SCV_PB_GPU_TOOL"; return ;; esac
  if command -v ioreg >/dev/null 2>&1 && [[ -n "$(pb_parse_ioreg "$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null)")" ]]; then printf ioreg
  elif command -v nvidia-smi >/dev/null 2>&1; then printf nvidia
  else printf none; fi
}

# @effect pb_gpu_read
# 이유: GPU 의 지금 값을 한 번 읽는다 — "사용률<탭>메모리 MB" (도구가 없으면 빈 글)
pb_gpu_read() {
  case "$1" in
    ioreg)  pb_parse_ioreg "$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null)" ;;
    nvidia) pb_parse_nvidia "$(nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits 2>/dev/null)" ;;
  esac
}

# @effect pb_timed
# 이유: 명령을 운영체제의 시간 재는 명령으로 감싸 돌리고 그 보고를 파일에 쓴다(없으면 셸의 time — 메모리는 재지 못함)
pb_timed() {
  local report="$1"; shift
  if [[ -x /usr/bin/time ]] && /usr/bin/time -l -p -o "$report" true >/dev/null 2>&1; then
    /usr/bin/time -l -p -o "$report" "$@" >/dev/null 2>&1          # BSD(맥)
  elif [[ -x /usr/bin/time ]] && /usr/bin/time -v -o "$report" true >/dev/null 2>&1; then
    /usr/bin/time -v -o "$report" "$@" >/dev/null 2>&1             # GNU(리눅스)
  else
    { TIMEFORMAT=$'real %R\nuser %U\nsys %S'; time "$@" >/dev/null 2>&1; } 2> "$report"
  fi
}

# @effect run_measured
# 이유: 명령 하나를 돌려 잰다 — "벽시계<탭>CPU<탭>메모리<탭>GPU 사용률<탭>GPU 메모리<탭>GPU 사용률 오름" (파이프라인의 입구)
run_measured() {
  local tool="$1" base="" before="" samples="$PB_TMP/gpu.samples" sum; shift
  : > "$samples"
  if [[ "$tool" != none ]]; then
    before="$(pb_gpu_read "$tool")"; base="${before#*$'\t'}"
    ( while :; do pb_gpu_read "$tool"; echo; sleep 0.2; done >> "$samples" ) &
    PB_SAMPLER=$!
  fi
  pb_timed "$PB_TMP/time.report" "$@"; echo "$?" > "$PB_TMP/exit"
  if [[ -n "$PB_SAMPLER" ]]; then kill "$PB_SAMPLER" 2>/dev/null; wait "$PB_SAMPLER" 2>/dev/null; PB_SAMPLER=""; fi
  sum=$'-\t-\t-'; [[ "$tool" == none ]] || sum="$(pb_gpu_summary "$(grep . "$samples")" "${base:-0}" "${before%%$'\t'*}")"
  printf '%s\t%s' "$(pb_parse_time "$(cat "$PB_TMP/time.report" 2>/dev/null)")" "$sum"
}

# @effect pb_load_now
# 이유: 지금 컴퓨터가 얼마나 붐비는지 잰다 — CPU 만 쓰는 짧은 반복의 벽시계 ÷ CPU × 100 (100 = 한가함)
pb_load_now() {
  local w c
  pb_timed "$PB_TMP/load.report" "$BASH" -c 'i=0; while [[ $i -ne 150000 ]]; do i=$((i + 1)); done'
  IFS=$'\t' read -r w c _ <<< "$(pb_parse_time "$(cat "$PB_TMP/load.report" 2>/dev/null)")"
  w="$(pb_to_milli "$w")" || w=0; c="$(pb_to_milli "$c")" || c=0
  if [[ $c -eq 0 ]]; then printf 100; else printf '%s' "$(( w * 100 / c ))"; fi
}

# @effect pb_measure_name
# 이유: 잰 값으로 판정 잣대를 고른다 — CPU 가 아닌 답이 나오면 붐빔을 한 번 재서 다시 고른다(붐비는 컴퓨터를 GPU 신호로 잘못 읽지 않게)
pb_measure_name() {
  local name; name="$(pb_pick_measure "$1" "$2" "$3" "$4" 100)"
  [[ "$name" == cpu ]] || name="$(pb_pick_measure "$1" "$2" "$3" "$4" "$(pb_load_now)")"
  printf '%s' "$name"
}

# @effect pb_bodies
# 이유: 사전 함수들이 있는 파일을 읽어 함수마다 "@@ 이름" 줄과 본문을 낸다 — 누가 누구를 부르는지 보려는 입구
pb_bodies() {
  local base="$1" files=() f seen=$'\n'
  while IFS=$'\x1d' read -r _ f _; do
    [[ -n "$f" && -f "$base/$f" ]] || continue
    case "$seen" in *$'\n'"$f"$'\n'*) continue ;; esac
    seen+="$f"$'\n'; files+=("$base/$f")
  done <<< "$(tr '\t' '\035' <<< "$2")"
  [[ ${#files[@]} -eq 0 ]] && return 0
  # 한 줄짜리 함수(이름() { … })는 그 줄의 나머지가 본문이다.
  LC_ALL=C awk '/^[A-Za-z_][A-Za-z0-9_]*\(\)[ \t]*\{/ {
                  name = $0; sub(/\(\).*/, "", name); print "@@ " name
                  rest = $0; sub(/^[^{]*\{/, "", rest); on = 1
                  if (rest ~ /\}[ \t]*$/) on = 0
                  if (rest ~ /[^ \t]/) print rest
                  next
                }
                on && /^\}/ { on = 0; next }
                on { print }' "${files[@]}"
}

# @effect pb_shim_dir
# 이유: 이름만 빌린 가짜 명령 묶음을 만든다 — 불린 이름을 한 줄 적고 진짜 명령을 돌린다(부른 횟수를 세는 장치)
pb_shim_dir() {
  local dir="$PB_TMP/shim" d f
  [[ -d "$dir" ]] && { printf '%s' "$dir"; return; }
  mkdir -p "$dir/.bin"
  cat > "$dir/.bin/shim" <<'SHIM'
#!/bin/sh
n="${0##*/}"; echo "$n" >> "$PB_COUNT"
IFS=:
for d in $PB_REALPATH; do [ -x "$d/$n" ] && [ ! -d "$d/$n" ] && exec "$d/$n" "$@"; done
echo "$n: not found" >&2; exit 127
SHIM
  chmod +x "$dir/.bin/shim"
  if command -v perl >/dev/null 2>&1; then
    perl -e 'my $dir = shift; for my $d (split /:/, $ENV{PATH}) { opendir(my $h, $d) or next; for (readdir $h) { next if /^\./; symlink(".bin/shim", "$dir/$_") unless -e "$dir/$_" || -l "$dir/$_" } }' "$dir"
  else
    local IFS=:
    for d in $PATH; do for f in "$d"/*; do [[ -e "$dir/${f##*/}" ]] || ln -s .bin/shim "$dir/${f##*/}" 2>/dev/null; done; done
  fi
  printf '%s' "$dir"
}

# @effect pb_count_execs
# 이유: 명령을 한 번 더 돌려, 그 명령이 이름으로 부른 다른 프로그램의 수를 센다(시간 재기와 따로 — 세는 장치가 시간을 흐린다)
pb_count_execs() {
  local shim count="$PB_TMP/count"; shim="$(pb_shim_dir)"; : > "$count"
  PB_COUNT="$count" PB_REALPATH="$PATH" PATH="$shim:$PATH" "$@" >/dev/null 2>&1
  grep -c . "$count"
}

# @effect pb_drive
# 이유: 사전의 함수 하나를 불러와 인자 글로 여러 번 부르고, 그 앞뒤의 CPU 시간을 파일에 쓴다(새 셸에서 돈다)
pb_drive() {
  set +eu +o pipefail
  local base="$1" rel="$2" fn="$3" args="$4" reps="$5" out="$6" count="${7:-}" r
  case "$rel" in
    lib/*|*/lib/*) source "$base/$rel" ;;
    *) eval "$(LC_ALL=C awk -v fn="$fn" '$0 ~ "^"fn"\\(\\)[[:space:]]*\\{" {on=1} on {print} on && /^\}$/ {exit}' "$base/$rel")" ;;
  esac
  declare -F "$fn" >/dev/null || exit 3
  if [[ "$args" == *"<<<"* ]]; then pb_call() { eval "$fn $args"; }; else pb_call() { eval "$fn $args" </dev/null; }; fi
  if [[ -n "$count" ]]; then      # 세는 실행 — 부르는 동안만 가짜 명령 묶음을 앞에 둔다
    local shim real="$PATH"; shim="$(pb_shim_dir)"; : > "$count"
    export PB_COUNT="$count" PB_REALPATH="$real"
    PATH="$shim:$real"; pb_call >/dev/null 2>&1; PATH="$real"
    exit 0
  fi
  times > "$out.a"
  for (( r = 0; r < reps; r++ )); do pb_call >/dev/null 2>&1; done
  times > "$out.b"
  exit 0
}

# @effect pb_measure_fn
# 이유: 사전의 함수 하나를 한 배(1 또는 4)의 입력으로 재서 한 줄을 낸다 — 되풀이 수를 맞추고, 시간 · 메모리 · GPU · 부른 횟수를 모은다
pb_measure_fn() {
  local tool="$1" base="$2" name="$3" rel="$4" args="$5" scale="$6" reps=5 try cpu="" m ms r2 wall tcpu rss gutil gmem grise out="$PB_TMP/drive"
  for try in 1 2 3; do
    m="$(run_measured "$tool" "$BASH" "$0" _drive "$base" "$rel" "$name" "$args" "$reps" "$out")"
    [[ -s "$out.b" ]] || { printf '%s\t%s\t-\t-\t-\t-\t-\t-\t-\tload-failed\t-\n' "$name" "$scale"; return; }
    cpu="$(LC_ALL=C awk -v a="$(pb_times_secs "$(cat "$out.a")")" -v b="$(pb_times_secs "$(cat "$out.b")")" 'BEGIN { printf "%.3f", b - a }')"
    r2="$(pb_reps_next "$cpu" "$reps")"; rm -f "$out.a" "$out.b"
    [[ "$r2" == "$reps" ]] && break
    [[ $try -lt 3 ]] && reps="$r2"
  done
  ms="$(LC_ALL=C awk -v c="$cpu" -v r="$reps" 'BEGIN { printf "%.3f", c * 1000 / r }')"
  "$BASH" "$0" _drive "$base" "$rel" "$name" "$args" 1 "$out" "$PB_TMP/fn.count" >/dev/null 2>&1
  IFS=$'\t' read -r wall tcpu rss gutil gmem grise <<< "$m"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tok\t%s\n' "$name" "$scale" "$reps" "$ms" "$wall" "$rss" "$gutil" "$gmem" "$(grep -c . "$PB_TMP/fn.count")" "$(pb_measure_name "$wall" "$tcpu" "$gmem" "$grise")"
}

CMD="${1:-}"; [[ $# -gt 0 ]] && shift
if [[ "$CMD" == _drive ]]; then pb_drive "$@"; fi
CATALOG="$( cd "$CORE_DIR/.." && pwd )/scv/core/catalog/pure"; BASE="$CORE_DIR"; ONLY=""; SCALE=1; COUNT=1; COMPOSED=0; TSV=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --catalog)  CATALOG="${2:-}"; shift 2 ;;
    --base)     BASE="${2:-}"; shift 2 ;;
    --only)     ONLY+="${2:-}"$'\n'; shift 2 ;;
    --scale)    SCALE="${2:-}"; shift 2 ;;
    --no-count) COUNT=0; shift ;;
    --composed) COMPOSED=1; shift ;;
    --tsv)      TSV="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) echo "pure-bench: 모르는 인자: $1" >&2; exit 2 ;;
  esac
done

case "$CMD" in
  env)
    printf 'bash %s · LC_ALL=%s · LANG=%s · GPU 도구 %s\n' "$BASH_VERSION" "${LC_ALL:-}" "${LANG:-}" "$(pb_gpu_tool)" ;;
  targets)
    [[ -d "$CATALOG" ]] || { echo "pure-bench: 사전 폴더가 없다: $CATALOG" >&2; exit 2; }
    pb_targets "$(read_catalog "$CATALOG")" "${ONLY%$'\n'}" ;;
  run)
    [[ $# -gt 0 ]] || { echo "pure-bench: run 뒤에 -- <명령…> 이 있어야 한다" >&2; exit 2; }
    TOOL="$(pb_gpu_tool)"
    M="$(run_measured "$TOOL" "$@")"
    N="-"; [[ $COUNT -eq 0 ]] || N="$(pb_count_execs "$@")"
    IFS=$'\t' read -r wall tcpu rss gutil gmem grise <<< "$M"
    RC="$(cat "$PB_TMP/exit" 2>/dev/null)"; RC="${RC:-0}"
    [[ "$RC" == 0 ]] || echo "pure-bench: 잰 명령이 종료 코드 $RC 로 끝났다 — 아래 값은 실패한 실행의 값이다" >&2
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$wall" "$tcpu" "$rss" "$gutil" "$gmem" "$N" "$(pb_measure_name "$wall" "$tcpu" "$gmem" "$grise")" "$RC" ;;
  fn)
    [[ -d "$CATALOG" ]] || { echo "pure-bench: 사전 폴더가 없다: $CATALOG" >&2; exit 2; }
    [[ "$SCALE" == 1 || "$SCALE" == 4 ]] || { echo "pure-bench: --scale 은 1 또는 4" >&2; exit 2; }
    TOOL="$(pb_gpu_tool)"
    while IFS=$'\x1d' read -r name rel lang a1 a4 sc; do
      [[ -n "$name" ]] || continue
      if [[ "$lang" != sh ]]; then printf '%s\t%s\t-\t-\t-\t-\t-\t-\t-\tnot-shell\t-\n' "$name" "$SCALE"; continue; fi
      if [[ "$SCALE" == 4 && "$sc" != 1 ]]; then printf '%s\t4\t-\t-\t-\t-\t-\t-\t-\tnot-scalable\t-\n' "$name"; continue; fi
      if [[ "$SCALE" == 4 ]]; then pb_measure_fn "$TOOL" "$BASE" "$name" "$rel" "$a4" 4
      else pb_measure_fn "$TOOL" "$BASE" "$name" "$rel" "$a1" 1; fi
    done <<< "$(pb_targets "$(read_catalog "$CATALOG")" "${ONLY%$'\n'}" | tr '\t' '\035')" ;;
  composed)
    [[ -d "$CATALOG" ]] || { echo "pure-bench: 사전 폴더가 없다: $CATALOG" >&2; exit 2; }
    T="$(pb_targets "$(read_catalog "$CATALOG")" "")"
    pb_composed "$(pb_calls "$(pb_bodies "$BASE" "$T")" "$(cut -f1 <<< "$T")")" ;;
  bench)
    [[ -d "$CATALOG" ]] || { echo "pure-bench: 사전 폴더가 없다: $CATALOG" >&2; exit 2; }
    ALL="$(pb_targets "$(read_catalog "$CATALOG")" "")"; CALLS=""
    if [[ $COMPOSED -eq 1 ]]; then
      CALLS="$(pb_composed "$(pb_calls "$(pb_bodies "$BASE" "$ALL")" "$(cut -f1 <<< "$ALL")")")"
      if [[ -n "${ONLY%$'\n'}" ]]; then
        KEEP=""; while IFS=$'\t' read -r cn cc; do case $'\n'"$ONLY" in *$'\n'"$cn"$'\n'*) KEEP+="$cn"$'\t'"$cc"$'\n' ;; esac; done <<< "$CALLS"
        CALLS="${KEEP%$'\n'}"
      fi
      WANT="$(tr '\t ' '\n\n' <<< "$CALLS" | grep . | sort -u)"
      [[ -n "$WANT" ]] || { echo "엮은 함수 없음 — 다른 사전 함수를 2개 이상 부르는 사전 함수가 없다"; exit 0; }
    else
      WANT="${ONLY%$'\n'}"
    fi
    TOOL="$(pb_gpu_tool)"; ROWS=""; CATTEXT="$(read_catalog "$CATALOG")"
    while IFS=$'\x1d' read -r name rel lang a1 a4 sc && IFS=$'\x1d' read -r rname role <&3; do
      [[ -n "$name" ]] || continue
      [[ "$rname" == "$name" ]] || role="-"
      if [[ "$lang" != sh ]]; then ROWS+="$(pb_row "$(printf '%s\t1\t-\t-\t-\t-\t-\t-\t-\tnot-shell\t-' "$name")" "" "$role")"$'\n'; continue; fi
      L1="$(pb_measure_fn "$TOOL" "$BASE" "$name" "$rel" "$a1" 1)"
      if [[ "$sc" == 1 && "$L1" == *$'\tok\t'* ]]; then L4="$(pb_measure_fn "$TOOL" "$BASE" "$name" "$rel" "$a4" 4)"
      else L4="$(printf '%s\t4\t-\t-\t-\t-\t-\t-\t-\tnot-scalable\t-' "$name")"; fi
      ROWS+="$(pb_row "$L1" "$L4" "$role")"$'\n'
    done <<< "$(pb_targets "$CATTEXT" "$WANT" | tr '\t' '\035')" 3<<< "$(pb_roles "$CATTEXT" "$WANT" | tr '\t' '\035')"
    ROWS="${ROWS%$'\n'}"
    [[ -z "$TSV" ]] || printf '%s\n' "$ROWS" > "$TSV"
    pb_render "$ROWS" "bash $BASH_VERSION · LC_ALL=${LC_ALL:-} · GPU 도구 $TOOL"; echo
    if [[ $COMPOSED -eq 1 ]]; then echo; pb_render_composed "$CALLS" "$ROWS"; echo; fi ;;
  *) echo "Usage: pure-bench.sh targets|env|run|fn|composed|bench … (파일 머리말 참고)" >&2; exit 2 ;;
esac
