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
# 종류: 꺼내기
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
