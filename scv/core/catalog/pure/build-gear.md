# 조립/gear — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 9개.

### scv_gear_args_apply
- 역할: 톱니가 선언한 인자 줄들에 덮는 값을 얹는다 — 선언한 이름만 남고, 덮는 묶음에 있으면 그 값, 없으면 기본값
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `$'count=3\nsince=' $'count=5\nother=1' → $'count=5\nsince='`
- 예: `"count=3" "" → "count=3"`
- 예: `"" "count=5" → ""`

### scv_gear_args_merge
- 역할: 인자 줄 두 묶음을 합친다 — 같은 이름은 뒤 묶음의 값이 이기고, 순서는 처음 나온 차례
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `$'count=3\nsince=' "count=5" → $'count=5\nsince='`
- 예: `"count=3" "sep=," → $'count=3\nsep=,'`
- 예: `"" "" → ""`

### scv_gear_ask_rows
- 역할: 기어나 톱니를 쓸 때 정해야 할 값을 줄로 만든다 — 인자마다 "arg<TAB>이름<TAB>지금 값<TAB>open|fixed<TAB>설명"(기어가 정해 둔 인자는 fixed), 받는 값이 있으면 끝에 "input<TAB>값 이름"
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `$'count=5\nsince=' "count=5" $'count\t낼 줄 수\nsince\t어디부터' "lines" → $'arg\tcount\t5\tfixed\t낼 줄 수\narg\tsince\t\topen\t어디부터\ninput\tlines'`
- 예: `"os=mac" "" $'os\t돌릴 곳: mac · linux' "none" → $'arg\tos\tmac\topen\t돌릴 곳: mac · linux'`
- 예: `"" "" "" "none" → ""`
- 예: `"" "" "" "text" → $'input\ttext'`

### scv_gear_confirm_text
- 역할: 밖으로 나가는 톱니 앞에서 낼 글을 만든다 — 확인 표(표:단계) · 단계 · 묻는 방법(질문 끝의 표와 두 보기) · 이어가는 명령 · 그 톱니가 돌릴 글
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"ab12cd34" "2/2 send — 보낸다" "git push" "gear.sh resume ab12cd34" "2" → $'GEAR_CONFIRM: ab12cd34\nGEAR_STEP: 2/2 send — 보낸다\n=== 밖으로 나가는 단계 ===\n사용자에게 선택 도구로 물어라 — 질문 글 끝에 [기어 확인 ab12cd34:2] 를 그대로 넣고, 보기는 "실행" 과 "실행하지 않음" 둘.\n"실행" 답이 온 뒤에만: gear.sh resume ab12cd34\n=== 이 단계가 돌릴 글 ===\ngit push'`

### scv_gear_handoff_text
- 역할: 판단 단계에서 모델에게 넘길 글을 만든다 — 이어가기 표 · 단계 · 그 기어의 글 · 앞 단계 결과 · 이어가는 명령
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"ab12cd34" "2/3 @sum — 요약" "글" "앞" "gear.sh resume ab12cd34" → $'GEAR_HANDOFF: ab12cd34\nGEAR_STEP: 2/3 @sum — 요약\n=== 이 단계의 글 ===\n글\n=== 앞 단계 결과 ===\n앞\n=== 이어가기 ===\n이 단계의 결과만 표준 입력으로 넘겨라: gear.sh resume ab12cd34'`

### scv_gear_index_build
- 역할: 사전 줄들을 이름 순(바이트 순)으로 늘어놓아 사전 글을 만든다 — 빈 줄은 뺀다
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `$'b\ttooth\tpure\t*\t*\t둘\t\na\ttooth\tpure\t*\t*\t하나\t' → $'a\ttooth\tpure\t*\t*\t하나\t\nb\ttooth\tpure\t*\t*\t둘\t'`
- 예: `"" → ""`

### scv_gear_list_rows
- 역할: 사전 글에서 목록에 낼 줄들을 만든다 — 톱니는 이름 · 표시 · 값 · 인자 · 하는 일, 기어는 이름 · 값 · 인자 · 하는 일(인자가 없으면 -)
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `$'g\tgear\t-\tlines\tlines\t앞 줄\t\tcount=3\nup\ttooth\tpure\ttext\ttext\t대문자\t' "gear" → $'g\tlines → lines\tcount=3\t앞 줄'`
- 예: `$'g\tgear\t-\tlines\tlines\t앞 줄\t\tcount=3\nup\ttooth\tpure\ttext\ttext\t대문자\t' "tooth" → $'up\tpure\ttext → text\t-\t대문자'`
- 예: `"" "gear" → ""`

### scv_gear_tooth_entry
- 역할: 톱니 사전에 덧붙일 항목 글을 만든다 — 이름 · 역할 · 표시 · 값 · 예시(있으면)
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"up" "대문자로" "pure" "text" "text" "\"a\" → \"A\"" → $'### up\n- 역할: 대문자로\n- 표시: pure\n- 값: text → text\n- 예: "a" → "A"'`
- 예: `"log" "커밋을 모은다" "effect" "none" "subjects" "" → $'### log\n- 역할: 커밋을 모은다\n- 표시: effect\n- 값: none → subjects'`

### scv_gear_turn_text
- 역할: 기어 턴에 실을 짧은 안내 글을 만든다 — 값 · 실행 · 답 세 줄. 값 줄은 값 안내 줄들(arg · input)을 쉬운 말로 옮기고(넣을 자료가 요청에 없으면 돌리기 전에 묻게 한다 — 물을 사람이 없으면 돌리지 않게), 실행 줄은 넣을 자료가 있으면 표준 입력으로 넣는 꼴을 보인다. 값 안내가 비면 값 안내 명령을 먼저 돌리게 한다. 선택 도구 이름이 있으면 빠진 값은 그 도구로 묻게 하고, 물을 사람이 없는 실행(다섯째 인자 1)이면 기본값을 쓰게 한다
- 위치: scripts/lib/gear.sh · @pure · sh
- 예: `"make-list" "/c/gear.sh" "" $'input\ttext' → $'[SCV 기어 턴] 이 요청은 저장해 둔 기어 make-list 를 돌리라는 것이다 — 가벼운 길: 도움말 · 요청 등록 · 다시 쓴 요청 인용 · 세 줄 끝 보고를 하지 않는다.\n1) 값: 넣을 자료는 표준 입력으로(text) — 인자가 아니다, 요청에 자료가 없으면 돌리기 전에 묻는다. 요청에 있는 값은 그대로 쓰고, 빠진 열린 값만 한 번에 묻는다(기본값으로 되면 묻지 않는다).\n2) 실행: printf \'%s\' \'넣을 자료\' | bash /c/gear.sh run make-list — 확인에서 멈추면 그 안내를 따른다.\n3) 답: 무엇을 돌렸고 결과가 무엇인지 두세 줄. 파일을 직접 고치지 않는다 — 고칠 일이면 그렇다고 말하고 끝낸다.'`
- 예: `"ci" "/c/gear.sh" "Pick" $'arg\tos\tmac\topen\t돌릴 곳: mac · linux\narg\tjobs\t4\tfixed\t겹쳐 돌릴 수' → $'[SCV 기어 턴] 이 요청은 저장해 둔 기어 ci 를 돌리라는 것이다 — 가벼운 길: 도움말 · 요청 등록 · 다시 쓴 요청 인용 · 세 줄 끝 보고를 하지 않는다.\n1) 값: 인자 os=mac(열림 — 돌릴 곳: mac · linux) · 인자 jobs=4(정해 둠 — 바꾸지 않는다). 요청에 있는 값은 그대로 쓰고, 빠진 열린 값만 Pick 로 한 번에 묻는다(기본값으로 되면 묻지 않는다).\n2) 실행: bash /c/gear.sh run ci 이름=값 … — 확인에서 멈추면 그 안내를 따른다.\n3) 답: 무엇을 돌렸고 결과가 무엇인지 두세 줄. 파일을 직접 고치지 않는다 — 고칠 일이면 그렇다고 말하고 끝낸다.'`
- 예: `"make-list" "/c/gear.sh" "" "" → $'[SCV 기어 턴] 이 요청은 저장해 둔 기어 make-list 를 돌리라는 것이다 — 가벼운 길: 도움말 · 요청 등록 · 다시 쓴 요청 인용 · 세 줄 끝 보고를 하지 않는다.\n1) 값: bash /c/gear.sh ask make-list 로 읽는다(arg 줄은 인자, input 줄은 표준 입력으로 넣을 자료). 요청에 있는 값은 그대로 쓰고, 빠진 열린 값만 한 번에 묻는다(기본값으로 되면 묻지 않는다).\n2) 실행: bash /c/gear.sh run make-list 이름=값 … (넣을 자료는 표준 입력) — 확인에서 멈추면 그 안내를 따른다.\n3) 답: 무엇을 돌렸고 결과가 무엇인지 두세 줄. 파일을 직접 고치지 않는다 — 고칠 일이면 그렇다고 말하고 끝낸다.'`
- 예: `"ci" "/c/gear.sh" "Pick" "none" 1 → $'[SCV 기어 턴] 이 요청은 저장해 둔 기어 ci 를 돌리라는 것이다 — 가벼운 길: 도움말 · 요청 등록 · 다시 쓴 요청 인용 · 세 줄 끝 보고를 하지 않는다.\n1) 값: 정할 값 없음. 요청에 있는 값은 그대로 쓰고, 물을 사람이 없는 실행이다 — 빠진 열린 값은 기본값을 쓰고, 쓴 기본값을 답에 적는다.\n2) 실행: bash /c/gear.sh run ci — 확인에서 멈추면 그 안내를 따른다.\n3) 답: 무엇을 돌렸고 결과가 무엇인지 두세 줄. 파일을 직접 고치지 않는다 — 고칠 일이면 그렇다고 말하고 끝낸다.'`
- 예: `"" "/c/gear.sh" "" "" → ""`
