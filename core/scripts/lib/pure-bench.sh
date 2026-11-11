#!/usr/bin/env bash
# pure-bench.sh (lib) — 재는 명령의 판단. 순수 함수만 둔다.
#
# 이 파일의 함수는 글만 받고 글만 낸다. 파일도, 시각도, 실행도 만지지 않는다.
# 사전을 읽고 명령을 돌려 재는 일은 바깥(core/scripts/pure-bench.sh)이 맡는다.
# 계약: core/contracts/composition.md · 계획: 20261111-wookiya1364-pure-bench-and-gate
#
# pb_targets 는 예시를 나누는 pc_split_example(lib/pure-catalog.sh)을 다시 쓴다 — 그 파일을 먼저 source 한다.

# 1배 입력 = 사전의 예시를 이만큼 되풀이한 것. 4배 입력은 그 네 배.
# 예시 그대로(두세 줄)는 너무 작아 함수를 부르는 값만 재진다.
PB_BASE_REPEAT=25

# @pure
# 역할: 예시의 인자 글에서 여러 줄 값은 줄을, 여러 줄 값이 없으면 낱말이 여럿인 값은 낱말을 N번 되풀이한다(늘릴 값이 없으면 그대로 내고 1)
# 종류: 변환
# 예: $'$\'a\\nb\' "x y"' 2 → $'$\'a\\nb\\na\\nb\' "x y"'
# 예: '"x y" k' 2 → '"x y x y" k'
# 예: '"1.2.3" k' 2 → '"1.2.3" k' [1]
pb_scale_args() {
  local args="${1:-}" times="${2:-1}" mode out i n c q open body rep k join did
  n=${#args}
  for mode in lines words; do
    out=""; q=""; body=""; open=""; did=0; i=0
    while [[ $i -lt $n ]]; do
      c="${args:i:1}"
      if [[ -z "$q" ]]; then
        if [[ "$c" == '$' && "${args:i+1:1}" == "'" ]]; then q=ds; open="\$'"; body=""; i=$((i + 2)); continue
        elif [[ "$c" == "'" ]]; then q=s; open="'"; body=""
        elif [[ "$c" == '"' ]]; then q=d; open='"'; body=""
        elif [[ "$c" == '\' ]]; then out+="$c${args:i+1:1}"; i=$((i + 1))
        else out+="$c"
        fi
      elif [[ "$c" == '\' && "$q" != s ]]; then
        body+="$c${args:i+1:1}"; i=$((i + 1))
      elif [[ ( "$q" == d && "$c" == '"' ) || ( "$q" != d && "$c" == "'" ) ]]; then
        # 값 하나가 끝났다 — 이 차례(mode)에 늘릴 값인가
        if [[ $mode == lines && $q == ds && "$body" == *'\n'* ]]; then
          join='\n'; [[ "$body" != *'\n' ]] || join=""
        elif [[ $mode == words && "$body" == *[![:space:]]*' '*[![:space:]]* ]]; then
          join=' '
        else
          join="-"
        fi
        if [[ "$join" == "-" ]]; then rep="$body"
        else
          rep=""; for (( k = 0; k < times; k++ )); do rep+="$body$join"; done
          [[ -z "$join" ]] || rep="${rep%"$join"}"
          did=1
        fi
        out+="$open$rep"; if [[ $q == d ]]; then out+='"'; else out+="'"; fi
        q=""
      else
        body+="$c"
      fi
      i=$((i + 1))
    done
    [[ -z "$q" ]] || out+="$open$body"   # 닫히지 않은 따옴표는 그대로 둔다
    if [[ $did -eq 1 ]]; then printf '%s' "$out"; return 0; fi
  done
  printf '%s' "$args"; return 1
}

# @pure
# 역할: 사전 글에서 잴 목록 "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림(1/0)" 줄들을 낸다(둘째 인자에 이름 목록을 주면 그 함수만, 예시 없는 함수는 뺀다)
# 종류: 꺼내기/measure
# 예: $'### f\n- 역할: 센다\n- 위치: scripts/lib/a.sh · @pure · sh\n- 예: `"1.2" → "2"`' "" → $'f\tscripts/lib/a.sh\tsh\t"1.2"\t"1.2"\t0'
# 예: $'### f\n- 위치: lib/a.sh · @pure · sh\n- 예: `"a" → "1"`\n### g\n- 위치: lib/a.sh · @pure · sh\n- 예: `"b" → "1"`' "g" → $'g\tlib/a.sh\tsh\t"b"\t"b"\t0'
pb_targets() {
  local catalog="${1:-}" only="${2:-}" line name="" file="" lang="" ex split args a1 a4 ok seen=""
  while IFS= read -r line; do
    case "$line" in
      '### '*) name="${line#\#\#\# }"; file=""; lang=""; seen="" ;;
      '- 위치: '*)
        file="${line#- 위치: }"; lang="${file##* · }"; file="${file%% · *}" ;;
      '- 예: `'*)
        [[ -n "$name" && -z "$seen" ]] || continue
        seen=1
        if [[ -n "$only" ]]; then case $'\n'"$only"$'\n' in *$'\n'"$name"$'\n'*) ;; *) continue ;; esac; fi
        ex="${line#- 예: \`}"; ex="${ex%\`}"
        split="$(pc_split_example "$ex")" || continue
        args="${split%%$'\t'*}"
        ok=1
        a1="$(pb_scale_args "$args" "$PB_BASE_REPEAT")" || ok=0
        a4="$(pb_scale_args "$args" "$(( PB_BASE_REPEAT * 4 ))")" || ok=0
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$file" "$lang" "$a1" "$a4" "$ok" ;;
    esac
  done <<< "$catalog"
}

# ---------------------------------------------------------------- 잰 글을 값으로
# 순수성 검사는 꺾쇠(크다 · 작다)를 파일 쓰기 · 읽기로 본다. 그래서 견주기는 셸의 정수 계산으로 하고,
# awk 를 쓰는 함수(외부 도구 — @deterministic)에서는 꺾쇠를 쓰지 않는다.

# @deterministic
# 역할: 시간 재는 명령의 출력 글에서 "벽시계 초<탭>CPU 초<탭>메모리 MB"를 낸다(BSD · GNU 두 꼴, 없는 값은 -)
# 종류: 꺼내기/measure
# 예: $'real 1.50\nuser 0.40\nsys 0.10\n  2621440  maximum resident set size' → $'1.50\t0.50\t2.5'
# 예: $'\tUser time (seconds): 0.40\n\tSystem time (seconds): 0.10\n\tElapsed (wall clock) time (h:mm:ss or m:ss): 0:01.50\n\tMaximum resident set size (kbytes): 2560' → $'1.50\t0.50\t2.5'
# 예: $'real 0.30\nuser 0.00\nsys 0.00' → $'0.30\t0.00\t-'
pb_parse_time() {
  LC_ALL=C awk '
    $1 == "real" { wall = $2; hw = 1 }
    $1 == "user" { u = $2; hc = 1 }
    $1 == "sys"  { s = $2; hc = 1 }
    /maximum resident set size/ { rss = $1 / 1048576; hr = 1 }
    /User time \(seconds\)/ { u = $NF; hc = 1 }
    /System time \(seconds\)/ { s = $NF; hc = 1 }
    /Elapsed \(wall clock\) time/ {
      t = $NF; wall = 0
      while ((k = index(t, ":")) != 0) { wall = wall * 60 + substr(t, 1, k - 1); t = substr(t, k + 1) }
      wall = wall * 60 + t; hw = 1
    }
    /Maximum resident set size \(kbytes\)/ { rss = $NF / 1024; hr = 1 }
    END {
      a = "-"; b = "-"; c = "-"
      if (hw) a = sprintf("%.2f", wall)
      if (hc) b = sprintf("%.2f", u + s)
      if (hr) c = sprintf("%.1f", rss)
      printf "%s\t%s\t%s", a, b, c
    }' <<< "${1:-}"
}

# @deterministic
# 역할: 셸의 times 출력 글(분 · 초 꼴 네 값)을 모두 더한 초로 낸다
# 종류: 변환
# 예: $'0m0.010s 0m0.020s\n0m1.000s 0m0.500s' → "1.530"
# 예: $'1m2.000s 0m0.000s\n0m0.000s 0m0.000s' → "62.000"
pb_times_secs() {
  LC_ALL=C awk '{ for (i = 1; i != NF + 1; i++) { m = index($i, "m"); if (m != 0) t += substr($i, 1, m - 1) * 60 + substr($i, m + 1) } } END { printf "%.3f", t }' <<< "${1:-}"
}

# @pure
# 역할: 잰 CPU 초와 되풀이 수를 보고 다음 되풀이 수를 낸다 — 0.2초에 못 미치면 0.3초가 되도록 늘린다(2000번까지)
# 종류: 세기
# 예: 0.010 5 → "150"
# 예: 0.250 5 → "5"
# 예: 0.000 5 → "2000"
pb_reps_next() {
  local c="${1:-0}" r="${2:-1}" whole frac ms num n
  whole="${c%%.*}"; frac=0; [[ "$c" != *.* ]] || frac="${c#*.}"
  frac="${frac}000"; frac="${frac:0:3}"
  (( ms = 10#${whole:-0} * 1000 + 10#$frac ))
  if [[ $ms -ge 200 ]]; then printf '%s' "$r"; return 0; fi
  n=2000
  if [[ $ms -ne 0 ]]; then (( num = r * 300 + ms - 1 )); (( n = num / ms )); fi
  [[ $n -le 2000 ]] || n=2000
  [[ $n -ge $r ]] || n="$r"
  printf '%s' "$n"
}

# @deterministic
# 역할: 맥의 그래픽 장치 정보 글에서 "사용률 %<탭>쓰는 메모리 MB"를 낸다(값이 없으면 빈 글)
# 종류: 꺼내기/measure
# 예: '"PerformanceStatistics" = {"In use system memory"=104857600,"Device Utilization %"=42}' → $'42\t100.0'
# 예: 'no gpu here' → ""
pb_parse_ioreg() {
  LC_ALL=C awk '
    match($0, /"Device Utilization %"=[0-9]+/) && u == "" { u = substr($0, RSTART, RLENGTH); sub(/.*=/, "", u) }
    match($0, /"In use system memory"=[0-9]+/) && m == "" { m = substr($0, RSTART, RLENGTH); sub(/.*=/, "", m) }
    END { if (u != "" && m != "") printf "%d\t%.1f", u, m / 1048576 }' <<< "${1:-}"
}

# @pure
# 역할: nvidia-smi 의 "사용률, 메모리 MiB" 줄들에서 "사용률 %<탭>쓰는 메모리 MB"를 낸다(장치가 여럿이면 사용률은 가장 큰 값, 메모리는 합)
# 종류: 꺼내기/measure
# 예: '35, 1024' → $'35\t1024.0'
# 예: $'10, 100\n90, 200' → $'90\t300.0'
# 예: '' → ""
pb_parse_nvidia() {
  local u m rest top="" sum=0 n=0
  while IFS=', ' read -r u m rest; do
    [[ "$u" =~ ^[0-9]+$ && "$m" =~ ^[0-9]+$ ]] || continue
    [[ -n "$top" && "$top" -ge "$u" ]] || top="$u"
    (( sum = sum + m )); (( n = n + 1 ))
  done <<< "${1:-}"
  [[ $n -eq 0 ]] || printf '%s\t%s.0' "$top" "$sum"
}

# @pure
# 역할: GPU 표본 줄들("사용률<탭>메모리 MB")과 시작 전 메모리에서 "평균 사용률 %<탭>늘어난 메모리 MB"를 낸다(표본이 없으면 "-<탭>-")
# 종류: 세기
# 예: $'40\t1100.0\n60\t1300.0' 1000.0 → $'50\t300.0'
# 예: '' 1000.0 → $'-\t-'
pb_gpu_summary() {
  local u m t n=0 s=0 top=0 base="${2:-0}" half avg d
  [[ "$base" == *.* ]] || base="${base}.0"
  base="${base%%.*}${base#*.}"; base="${base:0:${#base}}"
  while IFS=$'\t' read -r u m; do
    [[ "$u" =~ ^[0-9]+$ && "$m" =~ ^[0-9]+(\.[0-9])?$ ]] || continue
    [[ "$m" == *.* ]] || m="${m}.0"
    t="${m%%.*}${m#*.}"                       # 십분의 일 MB 를 정수로
    [[ $((10#$top)) -ge $((10#$t)) ]] || top="$t"
    (( s = s + u )); (( n = n + 1 ))
  done <<< "${1:-}"
  if [[ $n -eq 0 ]]; then printf -- '-\t-'; return 0; fi
  (( half = n / 2 )); (( avg = s + half )); (( avg = avg / n ))
  (( d = 10#$top - 10#$base )); [[ $d -ge 0 ]] || d=0
  printf '%s\t%s.%s' "$avg" "$(( d / 10 ))" "$(( d % 10 ))"
}
