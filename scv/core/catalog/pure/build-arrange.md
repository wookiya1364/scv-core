# 조립/arrange — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 3개.

### pa_hints
- 역할: 잰 줄들과 고른 순서에서 규칙으로 알 수 있는 것을 한 줄씩 낸다 — 앞으로 당긴 고르기, 합칠 수 있는 이어진 바꾸기, 일찍 끝나는 앞의 N줄. 없으면 "규칙으로 더 볼 것이 없음"
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'up\tmap\tA\t-\t0.134\t1.00\ntag\tmap\tB\t-\t0.083\t1.00\nkeep\tfilter\tC\t-\t0.032\t0.41' $'keep\nup\ntag' → $'고르기 keep 을 바꾸기 앞으로 당김 — 통과 비율 0.41\n이어진 바꾸기 2개(up · tag) — 한 명령으로 합칠 수 있으면 입력을 한 번만 훑는다'`
- 예: `$'k\tfilter\tA\t-\t0.1\t0.5\ntop\thead\t10\t-\t0\t0.1' $'k\ntop' → "앞의 10줄만 쓴다 — 흘려보내면 앞 단계가 일찍 끝난다"`
- 예: `$'k\tfilter\tA\t-\t0.1\t0.5\nup\tmap\tB\t-\t0.1\t1.00' $'k\nup' → "규칙으로 더 볼 것이 없음"`

### pa_pipeline
- 역할: 단계 줄들과 순서에서, 줄을 흘려보내는 셸 한 줄을 만든다 — 명령을 " | " 로 잇고 head 는 head -n N 으로 쓴다
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'up\tmap\ttr a-z A-Z\t-\nkeep\tfilter\tgrep 7\t-\ntop\thead\t100\t-' $'keep\nup\ntop' → "grep 7 | tr a-z A-Z | head -n 100"`
- 예: `$'up\tmap\ttr a-z A-Z\t-' "up" → "tr a-z A-Z"`

### pa_render
- 역할: 잰 줄들 · 짜임 줄들("이름표<탭>순서 글<탭>예상<탭>실제<탭>메모리<탭>답") · 도움 글 · 머리 글에서 사람이 읽는 표를 만든다
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'keep\tfilter\tgrep 7\t-\t0.030\t0.41' $'처음\tkeep\t0.030\t0.04\t3.1\t—' "규칙으로 더 볼 것이 없음" "입력 10줄" → $'입력 10줄\n\n| 단계 | 종류 | 한 번 잰 시간(초) | 통과 비율 | 순위 값 |\n|---|---|---|---|---|\n| keep | 고르기 | 0.030 | 0.41 | -19.66 |\n\n| 짜임 | 순서 | 예상(초) | 실제(초) | 메모리(MB) | 답 |\n|---|---|---|---|---|---|\n| 처음 | keep | 0.030 | 0.04 | 3.1 | — |\n\n규칙으로 본 것:\n- 규칙으로 더 볼 것이 없음'`
