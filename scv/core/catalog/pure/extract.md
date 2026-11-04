# 꺼내기 — 글 · JSON · 표에서 값이나 필드를 뽑는다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 54개.

### pc_extract_entries
- 역할: 소스 글에서 표식(어떤 주석 모양이든 '@pure 이름', 셸은 이름 없이도) 달린 함수마다 역할 · 종류 · 예시를 뽑아 항목 줄로 낸다
- 위치: scripts/lib/pure-catalog.sh · @deterministic · sh
- 예: `"lib/a.sh" <<< $'# @pure\n# 역할: 센다\n# 종류: 세기\n# 예: "a" → "1"\nf() {\n}' → $'lib/a.sh\tpure\tf\t센다\t세기\t"a" → "1"'`
- 예: `"src/a.ts" <<< $'// @pure add\n// 역할: 더한다\n// 종류: 세기\n// 예: 1 2 → 3\nexport const add = (a, b) => a + b' → $'src/a.ts\tpure\tadd\t더한다\t세기\t1 2 → 3'`
- 예: `"A.java" <<< $'/**\n * @deterministic clamp\n * 역할: 범위로 자른다\n * 종류: 다듬기\n * 예: 5 0 3 → 3\n */\nint clamp(int v, int lo, int hi)' → $'A.java\tdeterministic\tclamp\t범위로 자른다\t다듬기\t5 0 3 → 3'`

### pc_kinds_from_contract
- 역할: 계약 문서의 종류 표에서 종류 · 파일 이름 · 하는 일을 탭으로 뽑는다
- 위치: scripts/lib/pure-catalog.sh · @deterministic · sh
- 예: `<<< $'x\n| 종류 | 파일 | 하는 일 |\n|---|---|---|\n| 세기 | count | 센다 |\n\ny' → $'세기\tcount\t센다'`

### pc_lang_of
- 역할: 파일 경로의 확장자로 언어 표시를 낸다 — 언어 목록 없이, 확장자가 없으면 파일 이름
- 위치: scripts/lib/pure-catalog.sh · @pure · sh
- 예: `"src/date.ts" → "ts"`
- 예: `"lib/a.b/Makefile" → "Makefile"`
- 예: `"x.tar.gz" → "gz"`

### pc_split_example
- 역할: 예시 한 줄을 인자 · 기대 출력 · 기대 종료 코드 · 파이프 여부(1/0) 네 칸(탭)으로 나눈다
- 위치: scripts/lib/pure-catalog.sh · @pure · sh
- 예: `'"a" "b" → "ab"' → $'"a" "b"\t"ab"\t0\t0'`
- 예: `'"0.9" "1.0" → [1]' → $'"0.9" "1.0"\t\'\'\t1\t0'`
- 예: `'<<< "x" → "1" [2]' → $'<<< "x"\t"1"\t2\t0'`
- 예: `'"a|b" x | head → "a"' → $'"a|b" x | head\t"a"\t0\t1'`

### record_index_fields
- 역할: 색인 레코드 한 줄을 표시 · 키 · 파일 · 오프셋 · 길이 · 시각 · 요약 일곱 줄로 푼다
- 위치: scripts/lib/record-index.sh · @pure · sh
- 예: `$'decision\tk1\tf.md\t0\t5\tt\ts' → $'decision\nk1\nf.md\n0\n5\nt\ns'`

### scv_as_parse_terms
- 역할: 물음 한 줄을 낱말 목록(줄바꿈 구분)으로 쪼갠다 — 따옴표로 묶은 덩어리는 하나로 남긴다
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `'로그인 오류 수정' → $'로그인\n오류\n수정'`
- 예: `'"로그인 오류" 수정' → $'로그인 오류\n수정'`
- 예: `'' → ""`

### scv_choice_q_after
- 역할: 줄에서 사용자에게 묻는 마지막 문장 끝 물음표 뒤의 글을 꺼낸다 (그런 물음표가 없으면 아무것도 내지 않고 실패 1)
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `"할까요? 추천은 예." → " 추천은 예."`
- 예: `"끝났다." → [1]`

### scv_dreams_archive_dates
- 역할: "계획 이름 탭 archived_at" 줄들에서 보관 날짜 줄 "YYYYMMDD 탭 이름"을 날짜 · 이름 순으로 뽑는다(없는 날은 뺀다)
- 위치: scripts/lib/dreams.sh · @deterministic · sh
- 예: `$'b\t"2026-10-05T10:00:00Z"\na\t2026-10-05\nc\t2026-02-30' → $'20261005\ta\n20261005\tb'`

### scv_dreams_entries
- 역할: 세션 기록 JSONL(표준입력)에서 사람 메시지(U) · 모델 활동(A) · 등록 명령(G)을 기록 항목 줄로 뽑는다
- 위치: scripts/lib/dreams.sh · @deterministic · sh
- 예: `<<< $'{"type":"user","timestamp":"2026-10-01T01:00:00Z","message":{"role":"user","content":"hi there"}}\n{"type":"assistant","message":{"content":[{"type":"text","text":"ok"}]}}\n' → $'U\t2026-10-01T01:00:00Z\thi there\thi there\nA'`

### scv_dreams_human_turns
- 역할: 기록 항목 줄들에서 모델이 일한 사람 턴만 "세션 번호 시각 메시지" 줄로 뽑는다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `s1 $'U\t2026-10-01T01:00:00Z\thi\thi\nA\nU\t2026-10-01T02:00:00Z\tyo\tyo\nA'    → $'s1\t1\t2026-10-01T01:00:00Z\thi\ns1\t2\t2026-10-01T02:00:00Z\tyo'`

### scv_dreams_judge_parse
- 역할: 판정자 답 글에서 rule · advice 가 있는 첫 JSON 객체를 "규칙 탭 조언 탭 예시" 한 줄로 뽑는다(깨진 답은 빈 값)
- 위치: scripts/lib/dreams.sh · @deterministic · sh
- 예: `"{\"rule\":\"goal\",\"advice\":\"say the goal\",\"example\":\"do X\"}" → $'goal\tsay the goal\tdo X'`
- 예: `"no json" → ""`

### scv_dreams_register_features
- 역할: 기록 항목 줄들에서 사람 턴마다 마지막 등록 하나(goal · depth · finish)를 뽑는다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `s1 $'U\t2026-10-01T01:00:00Z\thi\thi\nG\t2026-10-01T01:01:00Z\tmsg\tctx\tasked'    → $'s1\t1\t2026-10-01T01:01:00Z\tmsg\tctx\tasked'`

### scv_graft_ask_summary
- 역할: ask JSON 에서 점수 높은 후보 n 개를 "경로:줄 US 이름" 줄로 낸다
- 위치: scripts/lib/graft.sh · @deterministic · sh
- 예: `'{"hits":[{"path":"a.py","line":3,"name":"foo","score":1},{"path":"b.py","line":9,"name":"bar","score":5}]}' → $'b.py:9\x1fbar\na.py:3\x1ffoo'`
- 예: `'{}' → ""`

### scv_graft_blast_summary
- 역할: blast JSON 을 "파일수 US 심볼수 US 상위" 한 줄로 줄인다
- 위치: scripts/lib/graft.sh · @deterministic · sh
- 예: `'{"files":[{"path":"a.py","symbols":[1,2]},{"path":"b.py","symbols":[1]}]}' → $'2\x1f3\x1fa.py:2 b.py:1'`
- 예: `'{}' → $'0\x1f0\x1f'`
- 예: `'not json' → ""`

### scv_graph_decision_refs
- 역할: DECISIONS.md 에서 결정 제목과 그 결정이 참조한 계획 slug 쌍을 "제목\x1fslug" 줄들로 뽑는다
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `$'## [2026-10-01 09:00] me — Do thing\n- refs: scv/promote/foo/PLAN.md, scv/archive/bar/PLAN.md\n' → $'Do thing\x1ffoo\nDo thing\x1fbar'`

### scv_graph_doc_links
- 역할: 마크다운 본문에서 상대 .md 링크만 뽑아 "문서\x1f대상(정규화)" 줄들로 낸다 (앵커 · URL · 이미지 제외)
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `"docs/a.md" $'see [b](b.md) and [c](../c.md#top) and [x](http://e.com/y.md) ![i](p.md)\n' → $'docs/a.md\x1fc.md\ndocs/a.md\x1fdocs/b.md'`

### scv_graph_plan_records
- 역할: awk 가 뽑은 T/E/S/B 레코드에서 경로 모양 토큰만 걸러 중복 없이 "slug\x1fepic\x1ftitle\x1ffiles" 한 줄로 낸다
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `s1 $'T\x1fTitle\nE\x1fep\nS\x1fcore/a.sh\nB\x1flib/z.sh\nB\x1fnoslash.md\nB\x1flib/z.sh\n' → $'s1\x1fep\x1fTitle\x1fcore/a.sh lib/z.sh'`

### scv_graph_plan_touches
- 역할: PLAN.md 본문에서 건드리는 파일(scope 항목 · 백틱 속 경로)을 뽑아 "slug\x1fepic\x1ftitle\x1ffiles" 한 줄로 낸다
- 위치: scripts/lib/graph.sh · @deterministic · sh
- 예: `s1 $'---\ntitle: "T one"\nepic: e1\nscope:\n  - core/a.sh\n  - b.md\n---\nbody `core/a.sh` and `x.md` and `lib/z.sh`\n' → $'s1\x1fe1\x1fT one\x1fcore/a.sh b.md lib/z.sh'`

### scv_graph_plans_batch
- 역할: 여러 계획의 awk 레코드(F 줄로 경계)를 계획마다 "slug\x1fepic\x1ftitle\x1factive\x1ffiles" 줄로 낸다 (경로에 /promote/ 가 있으면 active=1)
- 위치: scripts/lib/graph.sh · @pure · sh
- 예: `$'F\x1fscv/promote/20261101-a-x/PLAN.md\nT\x1fTitle\nE\x1fep\nB\x1flib/z.sh\n' → $'20261101-a-x\x1fep\x1fTitle\x1f1\x1flib/z.sh'`

### scv_hstate_nonce
- 역할: 상태에서 규약 지문(nonce) 필드만 꺼낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' → "deadbeef"`

### scv_hstate_parse
- 역할: 표식 JSON 한 줄(깨져도 됨)을 \x1f 로 구분한 상태 필드 여섯 개로 풀어 낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `'{"session":"s1","protocol":1,"turn":3,"diag":"ab12","diag_at":"09:30","nonce":"deadbeef"}' → $'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef'`
- 예: `'garbage' → $'\x1f0\x1f0\x1f\x1f\x1f'`

### scv_lang_new_text
- 역할: 이번 턴 어시스턴트 글 목록에서 지난 검사 id 뒤에 쓴 글만 잇고, 마지막 id 와 함께 낸다
- 위치: scripts/lib/lang-enforce.sh · @pure · sh
- 예: `$'a\x1fold\nb\x1fnew' a → $'b\x1fnew'`
- 예: `$'a\x1fone\nb\x1ftwo' zz → $'b\x1fone\ntwo'`
- 예: `"" a → ""`

### scv_mp_common
- 역할: 색인에서 모든 모델에 붙는 공통 원문의 파일과 날짜를 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'*\tcommon\tc.md\tu\t2026-01-01' → $'c.md\t2026-01-01'`
- 예: `$'m-1\tk1\tf1.md\tu\t2026-01-01\nm-2\tk2\tf2.md\tu\t2026-02-02' → ""`

### scv_mp_common_key
- 역할: 색인에서 공통(*) 행의 키를 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'*\tcommon\tc.md' → "common"`
- 예: `$'m-1\tk1\tf1.md\tu\t2026-01-01\nm-2\tk2\tf2.md\tu\t2026-02-02' → ""`

### scv_mp_guide_fold
- 역할: 모델이 실행한 mark 명령 사건들로 읽은 모델 집합을 쌓는다(경계 "B" 는 집합을 비운다)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `'' $'M\x1fbash model-prompting.sh mark --model Model-4' → $'model-4'`
- 예: `'m-1' $'B' → ""`

### scv_mp_harm_line
- 역할: 구역에서 통로(choice|text|none)에 맞는 "harm-" 줄의 값을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'tag: t\nharm-choice: C\nharm-text: T' choice → "C"`
- 예: `$'harm-text: T' none → ""`

### scv_mp_lookup
- 역할: 색인에서 모델 id 가 정확히 맞는 첫 행의 키 · 파일 · 날짜를 탭으로 잇는다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"m-2" $'m-1\tk1\tf1.md\tu\t2026-01-01\nm-2\tk2\tf2.md\tu\t2026-02-02' → $'k2\tf2.md\t2026-02-02'`
- 예: `"zz" $'m-1\tk1\tf1.md\tu\t2026-01-01\nm-2\tk2\tf2.md\tu\t2026-02-02' → ""`

### scv_mp_meta
- 역할: 색인의 "@이름" 행(예: refresh)의 값을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'@refresh\tr.sh' refresh → "r.sh"`
- 예: `$'@refresh\tr.sh' other → ""`

### scv_mp_principle_pick
- 역할: 원칙 파일 본문에서 이름이 맞는 구역의 전문을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'<!-- principle:english -->\nEN text\n<!-- principle:korean -->\nKO text' korean → "KO text"`
- 예: `$'<!-- principle:english -->\nEN text' korean → ""`

### scv_mp_principle_section
- 역할: 원칙 파일 본문에서 언어에 맞는 구역을 꺼낸다(없으면 english 구역)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'<!-- principle:english -->\nEN text\n<!-- principle:korean -->\nKO text' ko → "KO text"`
- 예: `$'<!-- principle:english -->\nEN text' ja → "EN text"`

### scv_mp_principle_tag
- 역할: 구역 첫 줄 "tag: " 뒤의 표식을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'tag: [P]\nbody' → "[P]"`
- 예: `body → ""`

### scv_mp_read_parse
- 역할: 읽음 기록 한 줄을 "지문 모델id" 두 칸으로 나눠 다듬는다(깨졌으면 빈 칸)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'abc\x1fm-1' → $'abc\x1fm-1'`
- 예: `abc → $'\x1f'`

### scv_mp_reg_seq
- 역할: 등록 첫 줄에서 세 번째 칸(차례)을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'t\x1fm\x1f7' → "7"`
- 예: `$'t\x1fm' → ""`

### scv_mp_register_rewrite
- 역할: 제출 텍스트에서 rewrite 행의 값(다시 쓴 요청)을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'a\tmsg\tv\nrewrite\t-\t다시 쓴 글' → "다시 쓴 글"`
- 예: `$'a\tmsg\tv' → ""`

### scv_mp_register_value
- 역할: 제출 텍스트(탭 구분)에서 항목 id 의 값을 꺼낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'a\tmsg\tv1\nb\tna\tv2' b → "v2"`
- 예: `$'a\tmsg\tv1' z → ""`

### scv_mp_turn_parse
- 역할: 이번 턴 기록 한 줄을 "지문 모델 결정 키" 로 나눈다(결정이 load|loaded 가 아니면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'n\x1fm\x1fload\x1fk' → $'n\x1fm\x1fload\x1fk'`
- 예: `$'n\x1fm\x1fnone\x1fk' → ""`

### scv_mx_parse_decisions
- 역할: DECISIONS.md 에서 (slug, verdict, 분 단위 시각) 결정 레코드를 탭 구분 줄로 뽑는다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'## [2026-10-01 09:00] me — t\n- verdict: adopted | x\n- refs: scv/promote/foo/PLAN.md\n' → $'foo\tadopted\t29847420'`

### scv_mx_parse_index
- 역할: INDEX.yaml 텍스트에서 slug · status · obsoleted_by 를 탭 구분 줄로 뽑는다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'- slug: a\n  status: adopted\n- slug: b\n  status: archived\n  obsoleted_by: a\n' → $'a\tadopted\t\nb\tarchived\ta'`

### scv_mx_parse_plan
- 역할: PLAN.md 프런트매터에서 대화 경로 · supersedes 개수 · 순수함수 절 유무를 한 줄로 뽑는다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'---\nraw_sources:\n  - scv/conversations/c1.md\n  - docs/x.md\nsupersedes: [a, b]\n---\n## 순수함수 · 파이프라인\n' → $'scv/conversations/c1.md\t2\t1'`

### scv_pd_declared
- 역할: 본문에서 순수 · 부수효과 선언(@pure · @deterministic · @effect)이 붙은 함수 이름들을 낸다
- 위치: scripts/lib/pure-declare.sh · @pure · sh
- 예: `sh $'# @pure\n# 역할: x\na() {' → "a"`
- 예: `js $'/** @effect save\n * 이유: 파일을 쓴다 */\nfunction save() {' → "save"`
- 예: `py $'# @pure\n\ndef f(x):\n    pass\ndef g(): pass' → "f"`
- 예: `sh $'a() {' → ""`

### scv_pd_functions
- 역할: 본문에서 이름 있는 함수 선언의 이름들을 나온 순서대로 낸다
- 위치: scripts/lib/pure-declare.sh · @pure · sh
- 예: `sh $'a() {\n  :\n}\nb() { :; }' → $'a\nb'`
- 예: `py $'def f(x):\n    return x' → "f"`
- 예: `js "" → ""`

### scv_pd_line_function
- 역할: 본문 한 줄이 이름 있는 함수 선언이면 그 이름을 낸다(아니면 빈 값)
- 위치: scripts/lib/pure-declare.sh · @pure · sh
- 예: `sh "foo_bar() {" → "foo_bar"`
- 예: `js "export async function loadMap(id) {" → "loadMap"`
- 예: `js "const pick = (a, b) => a" → "pick"`
- 예: `py "    def _helper(self, x):" → "_helper"`
- 예: `go "func (s *S) Run() error {" → "Run"`
- 예: `js "return fn(x)" → ""`

### scv_reg_line_key
- 역할: 실행 줄이 '시험 파일 하나를 bash 로 부르는 줄'이면 그 명령(키)을 낸다 — 아니면 빈 값
- 위치: scripts/lib/regression-memo.sh · @pure · sh
- 예: `"  bash core/tests/test-a.sh >/dev/null || fail a" → "bash core/tests/test-a.sh"`
- 예: `"bash tests/run.sh --quick" → "bash tests/run.sh --quick"`
- 예: `"bash core/tests/test-a.sh | tail -1" → ""`
- 예: `"bash -euo pipefail -c '" → ""`

### scv_reg_split_chain
- 역할: 한 줄을 &&, ||, ; 로 이은 조각들로 나눠 '조각<US>뒤 구분자' 줄들로 낸다 — 따옴표가 든 줄은 나누지 않는다
- 위치: scripts/lib/regression-memo.sh · @pure · sh
- 예: `"bash t/a.sh && bash t/b.sh || exit 1" → $'bash t/a.sh \x1f&&\n bash t/b.sh \x1f||\n exit 1\x1f'`
- 예: `"echo 'a && b'" → $'echo \'a && b\'\x1f'`

### scv_show_real_entries
- 역할: 세션 기록 JSONL(표준입력)에서 사용자 메시지 · 편집 · 실행 · 출력 · 확인 창 · 모델 글을 기록 항목 줄(U E R O X C Z T)로 뽑는다
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `"" <<< $'{"type":"user","timestamp":"2026-10-01T01:00:00Z","message":{"role":"user","content":"hi there"}}\n{"type":"assistant","message":{"content":[{"type":"text","text":"ok"}]}}\n' → $'U\t2026-10-01T01:00:00Z\thi there\thi there\nT\tok\tok'`

### scv_show_real_judge_parse
- 역할: 판정자 답 글에서 길이가 n 인 yes · no JSON 배열을 찾아 한 줄씩 낸다(깨진 답은 빈 값)
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `"Answer: [\"yes\",\"No\"]" 2 → $'yes\nno'`
- 예: `"[\"yes\"]" 2 → ""`

### scv_show_real_split
- 역할: 기록 항목 줄들을 사람 턴 줄들(시각 · 사건 글자 · 메시지 · 끝 글 · 보인 출력 줄)로 나눈다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `s1 $'U\t2026-10-01T01:00:00Z\tfix it\tfix it\nE\nR\nX\t5 passed\nT\tdone\tAll 5 passed.' "" "" "" → $'s1\t2026-10-01T01:00:00Z\tERTq\tfix it\tdone\tAll 5 passed.\t5 passed'`

### scv_turn_slice
- 역할: 턴 스트림에서 마지막 사람 프롬프트 뒤의 어시스턴트 텍스트만 줄바꿈으로 이어 낸다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'U\nA\x1fold\nU\nA\x1fnew1\x1esub\nA\x1fnew2\n' → $'new1\nsub\nnew2'`

### scv_writing_paragraphs
- 역할: 마크다운에서 코드 블록 · 제목 · 표 · HTML 밖 문단을 한 줄씩(줄바꿈은 공백으로) 꺼낸다 — 목록 항목은 따로
- 위치: scripts/lib/writing.sh · @deterministic · sh
- 예: `$'첫 줄\n둘째 줄\n\n# 제목\n- 항목 하나\n  이어짐' → $'첫 줄 둘째 줄\n- 항목 하나 이어짐'`
- 예: `$'```\n코드\n```' → ""`
- 예: `"" → ""`

### scv_writing_pass_criteria
- 역할: 시험서에서 통과 기준 줄('Pass criterion:' 줄과 '## Pass criteria' 절의 목록)만 꺼낸다
- 위치: scripts/lib/writing.sh · @deterministic · sh
- 예: `$'- **Pass criterion**: 잘 된다\n- **Run**: x' → "잘 된다"`
- 예: `$'## Pass criteria\n\n- 종료 코드 0\n## Next' → "종료 코드 0"`
- 예: `"" → ""`

### scv_writing_table_cells
- 역할: 마크다운에서 코드 블록 밖 표 칸을 꺼낸다 — 링크는 글자만, 백틱은 벗기고, 코드만 든 칸 · 구분 줄은 뺀다
- 위치: scripts/lib/writing.sh · @deterministic · sh
- 예: `$'| a | `x` |\n|---|---|\n| [링크](u) 글 | b |' → $'a\n링크 글\nb'`
- 예: `$'```\n| 코드 | 안 |\n```' → ""`
- 예: `"" → ""`

### settings_index_json
- 역할: JSON 객체의 모든 최상위 키를 "키 탭 값" 줄들로 꺼낸다(셸 이름으로 못 쓰는 키는 뺌)
- 위치: scripts/lib/settings.sh · @deterministic · sh
- 예: `'{"a":"x","b":2}' → $'a\tx\nb\t2'`

### settings_lookup_json
- 역할: JSON 객체에서 키 하나의 값을 문자열로 꺼낸다 — 없으면 빈 값
- 위치: scripts/lib/settings.sh · @deterministic · sh
- 예: `'{"a":"x","n":3}' a → "x"`
- 예: `'{"a":"x","n":3}' n → "3"`
- 예: `'{"a":"x"}' z → ""`

### settings_lookup_many_json
- 역할: JSON 객체에서 공백으로 나눈 키 여럿의 값을 "키 탭 값" 줄들로 꺼낸다
- 위치: scripts/lib/settings.sh · @deterministic · sh
- 예: `'{"a":"x","b":2}' 'a b' → $'a\tx\nb\t2'`
