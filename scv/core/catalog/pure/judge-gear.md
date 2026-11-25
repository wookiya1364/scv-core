# 판정/gear — 입력을 보고 예/아니오나 판정 이름 하나를 낸다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 15개.

### scv_gear_arg_name_ok
- 역할: 인자 이름이 쓸 수 있는 모양인지 가린다 — 영문 소문자로 시작, 영문 소문자 · 숫자 · 밑줄, 32자까지. _proxy 로 끝나는 이름은 이미 뜻이 있는 환경 변수라 못 쓴다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"count" → "yes"`
- 예: `"since_tag2" → "yes"`
- 예: `"Count" → "no"`
- 예: `"1st" → "no"`
- 예: `"http_proxy" → "no"`
- 예: `"" → "no"`

### scv_gear_args_split
- 역할: 실행할 때 받은 낱말들(한 줄에 하나)을 인자 줄들로 가린다 — "이름=값" 모양이고 이름이 쓸 수 있으면 그대로, 아니면 앞에 ! 를 붙인다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'count=2\nsince=v1 beta' → $'count=2\nsince=v1 beta'`
- 예: `$'Count=1\n=1\ncount' → $'!Count=1\n!=1\n!count'`
- 예: `"" → ""`

### scv_gear_args_unknown
- 역할: 준 인자 줄들 가운데 선언된 인자 줄들에 없는 이름을 찾는다 — 이름만, 한 줄에 하나
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'count=2\nnope=1' $'count=3\nsince=' → "nope"`
- 예: `"count=2" $'count=3' → ""`
- 예: `"x=1" "" → "x"`

### scv_gear_confirm_ok
- 역할: 선택 답이 '실행'을 고른 것인지 가린다 — 답이 정확히 "실행" 이나 "Run" 이거나, 그 뒤에 괄호 표시(추천 등)만 붙었을 때만
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"실행" → "yes"`
- 예: `"실행 (Recommended)" → "yes"`
- 예: `"실행하지 않음" → "no"`
- 예: `"실행 하지 마세요" → "no"`
- 예: `"Run" → "yes"`
- 예: `"Run later" → "no"`
- 예: `"Do not run" → "no"`

### scv_gear_example_mode
- 역할: 기어의 예시를 실제로 돌려 맞출지(run) 보기용으로 둘지(show) 정한다 — 펼친 흐름이 순수 톱니로만 되어 있을 때만 돌린다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'tooth\tup\ntooth\tcount' $'count\ttooth\tpure\ttext\tnumber\t센다\t\nup\ttooth\tpure\ttext\ttext\t대문자\t' → "run"`
- 예: `$'tooth\tup\ntext\tg' $'up\ttooth\tpure\ttext\ttext\t대문자\t' → "show"`
- 예: `$'tooth\tup\ntooth\twrite' $'up\ttooth\tpure\t*\t*\t대문자\t\nwrite\ttooth\teffect\t*\t*\t쓴다\t' → "show"`
- 예: `"" "" → "show"`

### scv_gear_flow_check
- 역할: 펼친 흐름(종류<TAB>이름 줄들 — tooth · text · unknown · error)을 사전과 맞춰 본다 — 없는 이름, 펼치다 생긴 오류, 앞 톱니가 돌려주는 값과 받는 값의 이름이 다른 것을 줄로 낸다(문제없으면 빈 값)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'tooth\tup\ntext\tg\ntooth\tcount' $'count\ttooth\tpure\ttext\tnumber\t센다\t\nup\ttooth\tpure\ttext\ttext\t대문자\t' → ""`
- 예: `$'tooth\tup\nunknown\tnope' $'up\ttooth\tpure\ttext\ttext\t대문자\t' → "2단계 nope — 사전에 없는 톱니 · 기어"`
- 예: `$'tooth\tcount\ntooth\tup' $'count\ttooth\tpure\ttext\tnumber\t센다\t\nup\ttooth\tpure\ttext\ttext\t대문자\t' → "2단계 up — 받는 값 text 가 앞 톱니가 돌려주는 값 number 와 다르다"`
- 예: `"" "" → "흐름이 비었다"`

### scv_gear_flow_mark
- 역할: 펼친 흐름에서 가장 센 표시 하나를 고른다 — 밖으로 나가는 톱니가 있으면 outward, 판단 단계가 있으면 judge, 부작용 톱니가 있으면 effect, 순수 톱니뿐이면 pure, 흐름이 비었거나 모르는 이름이 있으면 -
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'tooth\tup\ntooth\tcount' $'count\ttooth\tpure\ttext\tnumber\t센다\t\nup\ttooth\tpure\ttext\ttext\t대문자\t' → "pure"`
- 예: `$'tooth\tup\ntooth\twrite' $'up\ttooth\tpure\t*\t*\t대문자\t\nwrite\ttooth\teffect\t*\t*\t쓴다\t' → "effect"`
- 예: `$'tooth\tup\ntext\tg' $'up\ttooth\tpure\ttext\ttext\t대문자\t' → "judge"`
- 예: `$'tooth\tsend\ntext\tg' $'send\ttooth\toutward\t*\t*\t보낸다\t' → "outward"`
- 예: `$'tooth\tup\nunknown\tnope' $'up\ttooth\tpure\ttext\ttext\t대문자\t' → "-"`
- 예: `"" "" → "-"`

### scv_gear_flow_warn
- 역할: 펼친 흐름에서 가운데에 놓인 순수하지 않은 톱니를 찾는다 — 표시가 effect · outward 인데 맨 앞도 맨 끝도 아니면 알림 줄
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'tooth\tread\ntooth\tup\ntooth\twrite' $'read\ttooth\teffect\t*\t*\t읽는다\t\nup\ttooth\tpure\t*\t*\t대문자\t\nwrite\ttooth\teffect\t*\t*\t쓴다\t' → ""`
- 예: `$'tooth\tup\ntooth\tread\ntooth\tup' $'read\ttooth\teffect\t*\t*\t읽는다\t\nup\ttooth\tpure\t*\t*\t대문자\t' → "2단계 read — 표시가 effect 인데 흐름의 가운데에 있다(읽기는 맨 앞, 쓰기는 맨 끝에만)"`

### scv_gear_name_ok
- 역할: 기어 · 톱니 이름이 쓸 수 있는 모양인지 가린다 — 영문 소문자 · 숫자 · 붙임표, 첫 글자는 영문 소문자나 숫자, 64자까지. teeth 는 톱니 폴더 이름이라 못 쓴다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"release-notes" → "yes"`
- 예: `"Bad_Name" → "no"`
- 예: `"-x" → "no"`
- 예: `"teeth" → "no"`
- 예: `"" → "no"`

### scv_gear_pure_scan
- 역할: sh 글에서 순수 톱니에 둘 수 없는 명령이 든 줄을 찾는다 — 파일을 바꾸거나, 다른 코드를 돌리거나, 돌릴 때마다 달라지는 것. "줄 번호<TAB>낱말" 줄들
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'#!/usr/bin/env bash\ntr a-z A-Z' → ""`
- 예: `$'cat > out.txt' → $'1\t>'`
- 예: `$'awk \'$1 > 3\' | sort 2>/dev/null' → ""`
- 예: `$'mv a b\neval "$(cat)"\ndate +%s' → $'1\tmv\n2\teval\n3\tdate'`

### scv_gear_request_keep
- 역할: 쌓을 요청인지 가른다 — 자동 턴 · 명령으로 시작하는 글 · 기어를 돌리라는 줄이 붙은 글 · 짧은 글은 뺀다
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `"릴리스 노트를 써 줘" human → "1"`
- 예: `"릴리스 노트를 써 줘" auto → "0"`
- 예: `"/update" human → "0"`
- 예: `"응 이어가" human → "0"`
- 예: `$'목록 만들어 줘\n\n[SCV 기어] 이 요청에 맞는 저장해 둔 방법이 있음: make-list' human → "0"`

### scv_gear_risk_scan
- 역할: sh 글에서 밖으로 나가거나 지우는 명령이 든 줄을 찾는다 — "줄 번호<TAB>낱말" 줄들. 주석 줄은 보지 않는다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'#!/usr/bin/env bash\ncat\ngit push origin main' → $'3\tgit push'`
- 예: `$'cat\n\nrm -rf build' → $'3\trm'`
- 예: `$'git -C . push\n/usr/bin/curl -s x\nfind . -name x -delete' → $'1\tgit push\n2\tcurl\n3\tfind -delete'`
- 예: `$'# curl 을 쓰지 않는다\ncat' → ""`

### scv_gear_sig_check
- 역할: 기어에 적은 받는 값 · 돌려주는 값의 이름을 첫 톱니 · 끝 톱니의 이름과 맞춰 본다 — 다르면 오류 줄(어느 쪽이든 비었거나 * 이면 보지 않는다)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"lines" "lines" "lines" "lines" → ""`
- 예: `"number" "lines" "lines" "lines" → "in number — 첫 톱니가 받는 값 lines 와 다르다"`
- 예: `"lines" "number" "lines" "lines" → "out number — 끝 톱니가 돌려주는 값 lines 와 다르다"`
- 예: `"" "lines" "text" "*" → ""`

### scv_gear_step_mode
- 역할: 단계 하나를 어떻게 다룰지 정한다 — 톱니는 직접(direct), 기어의 글은 모델에게 넘김(handoff), 밖으로 표시 톱니는 확인 전에는 멈춤(confirm)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `tooth pure "" → "direct"`
- 예: `text - "" → "handoff"`
- 예: `tooth outward "" → "confirm"`
- 예: `tooth outward yes → "direct"`
- 예: `tooth "outward (push)" "" → "error"`
- 예: `tooth "?" "" → "error"`

### scv_gear_turn
- 역할: 요청 글이 기어를 돌리라는 것인지 가려 그 기어 이름을 낸다 — 글 첫 줄이 기어 액션 꼴(… gear run 이름)이거나, "[SCV 기어]" 로 시작하는 줄에 "gear run 이름" 이 있을 때. 이름은 주어진 기어 목록에 있어야 한다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"action:gear run release-ci os=mac" $'release-ci\nmake-list' → "release-ci"`
- 예: `$'목록 만들어 줘\n\n[SCV 기어] 이 요청에 맞는 저장해 둔 방법이 있음: make-list — 이 기어로 해 주세요(action:gear run make-list). 값은 위 요청에서 읽고, 없는 값은 물어 주세요.' $'release-ci\nmake-list' → "make-list"`
- 예: `"릴리스 검사 돌려 줘" $'release-ci\nmake-list' → ""`
- 예: `"기어가 뭐야? gear run 은 어떻게 써?" $'release-ci\nmake-list' → ""`
- 예: `"[SCV 기어] 이 요청에 맞는 저장해 둔 방법이 있음: nope — 이 기어로 해 주세요(action:gear run nope)." $'release-ci\nmake-list' → ""`
- 예: `"action:gear run release-ci" "" → ""`
