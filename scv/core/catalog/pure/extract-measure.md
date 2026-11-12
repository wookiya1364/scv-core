# 꺼내기/measure — 글 · JSON · 표에서 값이나 필드를 뽑는다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 6개.

### pb_calls
- 역할: 함수 본문 글("@@ 이름" 줄 뒤에 본문)과 사전의 이름 목록에서, 사전 함수마다 본문이 부르는 다른 사전 함수를 "함수<탭>부르는 함수들(빈칸으로 나눔)" 줄로 낸다(부르는 것이 없으면 뺀다)
- 위치: scripts/lib/pure-bench.sh · @deterministic · sh
- 예: `$'@@ f\n  g "$1" | h\n  # i 는 주석\n@@ g\n  echo x\n@@ z\n  f' $'f\ng\nh\ni' → $'f\tg h'`

### pb_parse_ioreg
- 역할: 맥의 그래픽 장치 정보 글에서 "사용률 %<탭>쓰는 메모리 MB"를 낸다(값이 없으면 빈 글)
- 위치: scripts/lib/pure-bench.sh · @deterministic · sh
- 예: `'"PerformanceStatistics" = {"In use system memory"=104857600,"Device Utilization %"=42}' → $'42\t100.0'`
- 예: `'no gpu here' → ""`

### pb_parse_nvidia
- 역할: nvidia-smi 의 "사용률, 메모리 MiB" 줄들에서 "사용률 %<탭>쓰는 메모리 MB"를 낸다(장치가 여럿이면 사용률은 가장 큰 값, 메모리는 합)
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `'35, 1024' → $'35\t1024.0'`
- 예: `$'10, 100\n90, 200' → $'90\t300.0'`
- 예: `'' → ""`

### pb_parse_time
- 역할: 시간 재는 명령의 출력 글에서 "벽시계 초<탭>CPU 초<탭>메모리 MB"를 낸다(BSD · GNU 두 꼴, 없는 값은 -)
- 위치: scripts/lib/pure-bench.sh · @deterministic · sh
- 예: `$'real 1.50\nuser 0.40\nsys 0.10\n  2621440  maximum resident set size' → $'1.50\t0.50\t2.5'`
- 예: `$'\tUser time (seconds): 0.40\n\tSystem time (seconds): 0.10\n\tElapsed (wall clock) time (h:mm:ss or m:ss): 0:01.50\n\tMaximum resident set size (kbytes): 2560' → $'1.50\t0.50\t2.5'`
- 예: `$'real 0.30\nuser 0.00\nsys 0.00' → $'0.30\t0.00\t-'`

### pb_roles
- 역할: 사전 글에서 "함수<탭>하는 일(짧게)" 줄들을 낸다 — 잴 목록과 같은 차례(예시 있는 함수만, 이름 목록을 주면 그 함수만), 하는 일은 풀이 앞까지 · 여덟 낱말까지
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'### f\n- 역할: 글을 낱말들로 나눈다 — 2자 이상(빈칸으로 이음)\n- 위치: lib/a.sh · @pure · sh\n- 예: `"a" → "1"`\n### g\n- 역할: 없다\n- 위치: lib/a.sh · @pure · sh' "" → $'f\t글을 낱말들로 나눈다'`
- 예: `$'### f\n- 역할: 하나 둘 셋 넷 다섯 여섯 | 일곱 여덟 아홉\n- 위치: lib/a.sh · @pure · sh\n- 예: `"a" → "1"`' "" → $'f\t하나 둘 셋 넷 다섯 여섯 / 일곱…'`

### pb_targets
- 역할: 사전 글에서 잴 목록 "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림(1/0)" 줄들을 낸다(둘째 인자에 이름 목록을 주면 그 함수만, 예시 없는 함수는 뺀다)
- 위치: scripts/lib/pure-bench.sh · @pure · sh
- 예: `$'### f\n- 역할: 센다\n- 위치: scripts/lib/a.sh · @pure · sh\n- 예: `"1.2" → "2"`' "" → $'f\tscripts/lib/a.sh\tsh\t"1.2"\t"1.2"\t0'`
- 예: `$'### f\n- 위치: lib/a.sh · @pure · sh\n- 예: `"a" → "1"`\n### g\n- 위치: lib/a.sh · @pure · sh\n- 예: `"b" → "1"`' "g" → $'g\tlib/a.sh\tsh\t"b"\t"b"\t0'`
