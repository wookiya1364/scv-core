#!/usr/bin/env bash
# timing.sh — 벽시계 예산을 기계 사정에 맞춘다 (v0.52.0+).
#
# 왜 있나: 몇몇 검사는 "이 일이 2초 안에 끝나야 한다" 로 알고리즘이 느려지는 것을 잡는다.
# 그 의도는 옳지만, 고정된 밀리초는 기계가 바쁠 때 같이 무너진다. 그러면 초록·붉음이
# 코드가 아니라 그 순간의 부하를 말하게 되고, 관문 하나를 공유하는 계획 25건이 함께 붉는다.
# 실제로 그 일이 났다 — 같은 관문이 한가할 때 348초에 통과하고 바쁠 때 431초에 무너졌다.
#
# 무엇을 하나: 아주 작은 고정 작업을 한 번 재서 이 셸이 기준보다 몇 배 굼뜬지 구하고,
# 예산에 그 배수를 곱한다. 한가한 기계에서는 배수가 1이라 예산이 그대로 남고 —
# 알고리즘이 정말 느려지면 여전히 잡힌다. 바쁜 기계에서는 예산이 같이 늘어난다.
# 배수에는 상한을 둔다. 그러지 않으면 아주 바쁜 기계에서 어떤 느림도 통과해 버린다.
#
# 재는 것은 source 할 때 딱 한 번이다. 예산을 물을 때마다 재면 같은 실행 안에서도
# 답이 흔들려, 고치려던 바로 그 병을 다시 만든다.
#
# 쓰는 법:
#   source "<tests>/lib/timing.sh"
#   t0=$(scv_now_ms); <잴 일>; t1=$(scv_now_ms)
#   (( t1 - t0 <= $(scv_budget_ms 2000) )) && ok "..." || fail "..."
#
# 강제로 정하고 싶으면 SCV_TEST_TIME_SCALE=<배수> 를 준다 (CI 재현용).

# 한가한 기계에서 아래 보정 작업이 걸리는 시간(ms). 이 값과의 비가 배수가 된다.
# 측정에는 date 를 부르는 비용이 섞이므로, 작업을 충분히 크게 잡아 그 몫을 작게 만든다.
# 기준은 넉넉히 잡는다 — 한가한데 배수가 2로 튀면 경계에서 답이 흔들린다.
SCV_TIME_REF_MS=${SCV_TIME_REF_MS:-300}
# 배수 상한. 이보다 바쁜 기계에서는 더 봐주지 않는다 — 봐주면 검사가 의미를 잃는다.
SCV_TIME_SCALE_MAX=${SCV_TIME_SCALE_MAX:-8}

# 밀리초. date 가 %3N 을 모르면 python3, 그것도 없으면 초 단위로 떨어진다.
scv_now_ms() {
  local n
  n="$(date +%s%3N 2>/dev/null || true)"
  [[ "$n" =~ ^[0-9]+$ ]] || n="$(python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || true)"
  [[ "$n" =~ ^[0-9]+$ ]] || n=$(( $(date +%s) * 1000 ))
  printf '%s' "$n"
}

# 고정 작업 한 번의 소요(ms). 셸 산술만 쓴다 — 디스크도 네트워크도 타지 않아
# 재는 것이 "이 셸이 지금 얼마나 굼뜬가" 하나로 좁혀진다.
scv_calibrate_ms() {
  local t0 t1 i s=0
  t0=$(scv_now_ms)
  for ((i = 0; i < 100000; i++)); do s=$((s + i)); done
  t1=$(scv_now_ms)
  printf '%s' "$(( t1 - t0 ))"
}

# source 시점에 한 번 정해지는 배수. 이후로는 다시 재지 않는다.
if [[ -n "${SCV_TEST_TIME_SCALE:-}" && "${SCV_TEST_TIME_SCALE}" =~ ^[0-9]+$ ]]; then
  SCV_TIME_SCALE=$SCV_TEST_TIME_SCALE
else
  _scv_calib=$(scv_calibrate_ms)
  [[ "$_scv_calib" =~ ^[0-9]+$ ]] || _scv_calib=$SCV_TIME_REF_MS
  # 올림 나눗셈 — 기준을 넘어서면 곧바로 2배가 된다.
  SCV_TIME_SCALE=$(( (_scv_calib + SCV_TIME_REF_MS - 1) / SCV_TIME_REF_MS ))
  (( SCV_TIME_SCALE < 1 )) && SCV_TIME_SCALE=1
  (( SCV_TIME_SCALE > SCV_TIME_SCALE_MAX )) && SCV_TIME_SCALE=$SCV_TIME_SCALE_MAX
  unset _scv_calib
fi

# 이 셸의 배수.
scv_time_scale() { printf '%s' "$SCV_TIME_SCALE"; }

# <예산 ms> → 이 기계에 맞춘 예산 ms.
scv_budget_ms() {
  local budget="${1:-0}"
  [[ "$budget" =~ ^[0-9]+$ ]] || budget=0
  printf '%s' "$(( budget * SCV_TIME_SCALE ))"
}
