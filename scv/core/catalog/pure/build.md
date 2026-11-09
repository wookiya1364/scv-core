# 조립 — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 65개.

### env_settings_unset_args
- 역할: SCV_ENV_LOADED_KEYS 의 키마다 "-u 키" 두 줄을 내 env 명령에 넘길 인자를 만든다(환경변수 필요)
- 위치: scripts/lib/env.sh · @pure · sh
- 예: `→ ""`

### pc_render_catalog
- 역할: 항목 · 종류 표 · 다른 언어 짝으로 사전 파일들(차례 + 종류별)의 글을 만든다. 파일마다 '@@FILE 이름' 줄로 시작, 항목에 언어 표시
- 위치: scripts/lib/pure-catalog.sh · @deterministic · sh
- 예: `$'lib/a.sh\tpure\tf\t센다\t세기\t"a" → "1"' $'세기\tcount\t센다' → $'@@FILE INDEX.md\n# 순수함수 사전 — 차례\n\n> 생성물 — 손으로 고치지 말 것. 다시 만들기: `bash core/scripts/pure-catalog.sh build`\n>\n> 새 함수를 만들기 전에: 아래에서 종류를 고르고, 그 종류 파일 하나만 연다.\n\n| 종류 | 하는 일 | 개수 | 파일 |\n|---|---|---|---|\n| 세기 | 센다 | 1 | [count.md](count.md) |\n\n전체 1개\n@@FILE count.md\n# 세기 — 센다\n\n> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 1개.\n\n### f\n- 역할: 센다\n- 위치: lib/a.sh · @pure · sh\n- 예: `"a" → "1"`'`

### record_index_entry
- 역할: 종류 · 키 · 파일 · 오프셋 · 길이 · 시각 · 요약을 탭으로 이은 색인 한 줄을 만든다 — 잘못된 입력은 빈 값
- 위치: scripts/lib/record-index.sh · @pure · sh
- 예: `decision k1 f.md 0 10 2026-01-01 요약 → $'decision\tk1\tf.md\t0\t10\t2026-01-01\t요약'`
- 예: `nope k1 f.md 0 10 t s → ""`

### run_manifest_path
- 역할: 계획 슬러그로 실행 매니페스트 파일 경로를 만든다
- 위치: scripts/lib/run-manifest.sh · @pure · sh
- 예: `my-plan → "test-results/.scv/my-plan.manifest"`
- 예: `my-plan out → "out/.scv/my-plan.manifest"`

### scv_as_render
- 역할: 묶음 줄들을 사람이 읽는 검색 결과 글로 만든다 — 없으면 못 찾았다고 말한다
- 위치: scripts/lib/archive-search.sh · @deterministic · sh
- 예: `'' 0 1 5 x → $'ARCHIVE_SEARCH: 0\n찾은 것이 없습니다.'`

### scv_choice_line
- 역할: 선택지 도구 이름으로 매 턴 싣는 안내 한 줄을 만든다 (도구 이름이 비면 아무것도 내지 않는다; 전문은 도구 이름을 넣은 긴 한 줄)
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `"" → ""`

### scv_choice_reason
- 역할: 글로 묻고 끝낸 턴을 막을 때 모델에게 보이는 이유 한 줄(규칙 요지)을 만든다
- 위치: scripts/lib/choices.sh · @pure · sh
- 예: `ChoiceTool → $'[SCV 선택지] 사용자에게 고르게 하거나 묻는 글로 턴을 끝냈다 — ChoiceTool 로 다시 물어라: 결정 하나에 질문 하나, 첫 보기가 추천, 보기마다 그 보기가 부를 문제를 막는 방법, 질문이 4개를 넘으면 중요한 것부터 나눠 연달아, 보기가 4개를 넘으면 두 단계로. 고를 것이 아니면 질문 없이 끝내라(contracts/choices.md).'`

### scv_delegate_block
- 역할: 위임 스위치가 켜진 프로젝트에 싣는 고정 지시 블록(깊은 질문은 배경 조사로)을 낸다 — 인자 없음
- 위치: scripts/lib/force-help.sh · @pure · sh
- 예: `→ $'[SCV delegate] 깊은 질문은 배경 조사로 (SCV_DELEGATE_EFFORT=on).\n- 답은 지금, 세션 그대로 한다. 세션의 노력 단계는 SCV 가 건드리지 않는다.\n- 질문이 깊으면 — 여러 파일을 읽거나 검증이 필요하면 — 호스트에 배경 조사\n  에이전트 scv-investigator 가 있을 때 그것에 넘기고, 답에 "깊은 결과가\n  뒤따른다" 고 한 줄 적는다. 에이전트가 없으면 그냥 답한다.\n- 조사 결과의 전문은 scv/raw/YYYYMMDD-research-주제.md 로 남기게 하고,\n  알림에는 요약만 받는다 — 알림 본문은 잘린다.\n- 위임 도구가 호출별 노력 단계를 지원하면 깊이에 맞춰 고른다. 지원하지\n  않으면 세션 그대로 배경 실행한다.\n- 결과가 도착하면 raw 파일 경로와 요약 한 줄을 세션의 대화 파일에 이어 붙인다.\n- 얕은 질문은 위임하지 않는다. 끄는 법: scv/scv_settings.json SCV_DELEGATE_EFFORT=off.'`

### scv_dreams_judge_prompt
- 역할: 개선점 줄 하나와 가린 발췌들로 판정자에게 보낼 질문 글을 만든다(개선점이 없으면 빈 값)
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'finish\t1\t3\t\ts1/1' $'fix it' → $'You coach a person on writing better prompts for an AI coding assistant. Answer with one JSON object only.\n\nFinding from their recent sessions: 요청에 완료 기준(무엇이 되면 끝인지)을 직접 말한 비율 1/3(33%).\n\nSuggested prompting-guide rule: finish (name the rule from the model\'s official prompting guide that fits best).\n\nExcerpts of the person\'s own requests (redacted):\n1. fix it\n\nReply with exactly one JSON object: {"rule": "GUIDE RULE NAME", "advice": "ONE OR TWO SENTENCES: WHAT TO ADD NEXT TIME", "example": "ONE REWRITTEN REQUEST"}. Write advice and example in the same language as the excerpts. Do not include paths, emails, names, or ids.'`
- 예: `"" "" → ""`

### scv_dreams_ratio
- 역할: 두 수로 비율 "n.n"(소수 한 자리 반올림)을 만든다(나누는 수가 0 이면 "-")
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `7 2 → '3.5'`
- 예: `1 0 → '-'`

### scv_dreams_render_html
- 역할: 기간 · 분포 · 개선점 · 근거 · 조언 줄들로 한 파일짜리 드림 보고서 HTML 을 만든다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `"" "" "" "" "" stamp month 0 0 0 → $'<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">\n<title>SCV 드림</title><style>:root{--bg:#171922;--panel:#1e1e1e;--line:#3a3d4a;--text:#e7e9f0;--muted:#9096a8;--accent:#7aa2f7;--warn:#e0af68}\nbody{margin:0;background:var(--bg);color:var(--text);font:15px/1.6 -apple-system,"Segoe UI",sans-serif}\nmain{max-width:880px;margin:0 auto;padding:24px 16px}h1{font-size:22px;margin:0 0 4px}h2{font-size:17px;margin:28px 0 8px}\n.muted{color:var(--muted)}.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px 16px;margin:10px 0}\ntable{border-collapse:collapse;width:100%}th,td{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left}td.n{text-align:right}\nsvg{width:100%;height:auto;margin:8px 0}svg .v{fill:var(--text);font-size:11px}svg .l{fill:var(--muted);font-size:10px}svg .axis{stroke:var(--line)}\n.ex{border-left:3px solid var(--line);padding-left:10px;margin:6px 0;color:var(--muted)}.adv{border-left:3px solid var(--accent);padding-left:10px;margin:8px 0}\n.none{color:var(--warn)}\n</style></head><body><main>\n<h1>SCV 드림 — 프롬프트 코치</h1><p class="muted">stamp · 세션 0개 · 사람 질의 0번 · 등록 0건 · 기간 단위: 달</p>\n<div class="card">아직 셀 것이 없음 — 기록이 있는 동안 보관된 계획이 0개다. 지금까지 사람 질의 0번.</div>\n<h2>기간별 질의 ÷ 보관</h2>\n<p class="muted">아직 셀 것이 없음 — 세션 기록에서 사람 질의를 찾지 못했다.</p>\n<h2>계획마다 보관까지 걸린 질의</h2>\n<p class="muted">아직 셀 것이 없음 — 기록이 있는 동안 보관된 계획이 없다.</p>\n<h2>개선점</h2>\n<p class="muted">규칙에 걸린 개선점이 없다.</p>\n<p class="muted">드림은 입력(세션 기록 · 보관 기록)을 바꾸지 않는다. 발췌는 경로 · 메일 · 비밀값 · id 를 가린 짧은 글이다. 규칙: protocols/dreams.md</p></main></body></html>'`

### scv_dreams_render_summary
- 역할: 기간 · 개선점 줄들로 다음 턴에 싣는 [SCV 드림] 한 줄 요약을 만든다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `"" "" report.html 0 → '[SCV 드림] 아직 셀 것이 없음(보관된 계획 0개 · 사람 질의 0번) · 보고서 report.html'`

### scv_dreams_svg_bars
- 역할: 제목과 "라벨 탭 값" 줄들로 막대 차트 SVG 한 덩이를 만든다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `t $'a\t2\nb\t4' '#fff' → '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 220" role="img" aria-label="t"><rect x="30" y="105" width="76" height="75" rx="3" fill="#fff"><title>a: 2</title></rect><text x="68" y="101" text-anchor="middle" class="v">2</text><text x="68" y="198" text-anchor="middle" class="l">a</text><rect x="110" y="30" width="76" height="150" rx="3" fill="#fff"><title>b: 4</title></rect><text x="148" y="26" text-anchor="middle" class="v">4</text><text x="148" y="198" text-anchor="middle" class="l">b</text><line x1="26" y1="180" x2="630" y2="180" class="axis"/></svg>'`

### scv_dreams_tip_text
- 역할: 개선점 줄 하나를 사람이 읽는 한 문장으로 만든다
- 위치: scripts/lib/dreams.sh · @pure · sh
- 예: `$'finish\t1\t3\t\ts1/1' → '요청에 완료 기준(무엇이 되면 끝인지)을 직접 말한 비율 1/3(33%)'`
- 예: `$'plan\t12\t4\tplan-a\t' → '보관까지 질의가 많았던 계획 plan-a — 12번(중앙값 4번)'`

### scv_drift_line
- 역할: 시각 · 턴 · 메아리 판정 · 위반 수 · reload 를 드리프트 로그 한 줄로 만든다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `09:30 3 ok $'lead-missing\n' 1 → "09:30 turn=3 echo=ok lint=1 reload=1"`
- 예: `09:30 3 ok "" 0 host → "09:30 turn=3 echo=ok lint=0 reload=0 src=host"`

### scv_evidence_render
- 역할: 근거 목록을 사람이 읽을 기록용 불릿 줄들로 만든다
- 위치: scripts/lib/finish-report.sh · @pure · sh
- 예: `$'test\x1f언어 시험 실행\x1ffail\x1fbash t.sh' korean → "- 시험 · 실패 · 언어 시험 실행"`
- 예: `$'read\x1fa.md\x1fok\x1fdocs/a.md' english → "- read · ok · a.md"`
- 예: `"" korean → ""`

### scv_finish_note
- 역할: 끝 보고 문제 줄들을 설정 언어로 된 교정 문구 한 줄로 만든다
- 위치: scripts/lib/finish-report.sh · @pure · sh
- 예: `$'missing\x1funverified\nmissing\x1fdecided' korean → "[SCV 확인 범위] 끝 보고에 고칠 것 — 빠진 줄: 확인 못 한 것 · 제가 대신 정한 것. 고친 줄만 끝에 덧붙여라(본문: contracts/finish-report.md)."`
- 예: `$'undisclosed\x1ftest-a.sh' korean → "[SCV 확인 범위] 끝 보고에 고칠 것 — 고치기 전 실패를 못 본 시험('확인 못 한 것'에 적어라): test-a.sh. 고친 줄만 끝에 덧붙여라(본문: contracts/finish-report.md)."`
- 예: `"" korean → ""`

### scv_finish_rule_line
- 역할: 매 턴 맨 앞에 실을 확인 범위 안내 한 줄을 설정 언어로 만든다
- 위치: scripts/lib/finish-report.sh · @pure · sh
- 예: `korean → "[SCV 확인 범위] 도구를 쓴 턴은 끝 보고 끝에 '확인한 것 · 확인 못 한 것 · 제가 대신 정한 것'(기록 · 질문만 쓴 턴은 '확인 범위:' 한 줄). '없음'엔 이유, 실패를 못 본 시험은 '확인 못 한 것'에. 본문: contracts/finish-report.md"`
- 예: `english → "[SCV verification scope] A turn that used tools ends its final report with Verified · Not verified · Decided for you (only SCV records or questions: one 'Verification scope:' line). 'none' needs a reason; a test never seen failing goes under Not verified. Body: contracts/finish-report.md"`
- 예: `"" → "[SCV verification scope] A turn that used tools ends its final report with Verified · Not verified · Decided for you (only SCV records or questions: one 'Verification scope:' line). 'none' needs a reason; a test never seen failing goes under Not verified. Body: contracts/finish-report.md"`

### scv_force_banner
- 역할: 준비가 켜져 있으면(on) 화면 표시줄 한 줄을 내고, 아니면 빈 값
- 위치: scripts/lib/force-help.sh · @pure · sh
- 예: `off → ""`
- 예: `on → "[SCV preflight] 이번 턴의 프로젝트 상태를 함께 실었다."`

### scv_force_routing
- 역할: 매 턴 맨 앞에 싣는 고정 지시 블록(SCV help 를 먼저 부르라)을 낸다 — 인자 없음
- 위치: scripts/lib/force-help.sh · @pure · sh
- 예: `→ $'════ SCV: 이 턴의 첫 행동 ════\n답을 쓰기 전에, 이 메시지 전문을 인자로 SCV help 액션을 지금 호출하라 — 다른 도구 · 조사 · 수정보다 먼저(부르기 전 다른 도구는 거절된다 — 호스트가 허용한 진행 표시 도구만 함께 보낼 수 있다).\n**판단하지 말고 부르라** — 부를 필요는 help 가 판단한다. 부르지 않는 경우는 둘뿐: 이 턴에 **이미 SCV 액션이 실려 있거나**,\n**사람이 쓰지 않은 자동 알림**이거나. 그 외에는 예외가 없다. 부르지 않으면 **이 논의는 어디에도 남지 않는다** — help 가 파일로 남긴다.\n아래 진단은 **상태를 다시 조회하지 않는 데에만** 쓰라 — 호출을 건너뛸 이유가 되지 않는다. 끄기: scv/scv_settings.json SCV_ALWAYS_ON=off.'`

### scv_gates_reason
- 역할: 받은 막는 이유들(최대 5개) 중 빈 것을 빼고 한 줄씩 이어 막는 이유를 만든다
- 위치: scripts/lib/stop-gates.sh · @pure · sh
- 예: `등록 '' 선택지 → $'등록\n선택지'`
- 예: `'' '' '' → ""`

### scv_gates_record
- 역할: 막은 검사들을 이어 새 전달 기록 한 줄을 만든다 — 막은 것이 없으면 빈 값
- 위치: scripts/lib/stop-gates.sh · @pure · sh
- 예: `s t '' 0 g1 → $'s\x1ft\x1fg1'`
- 예: `s t $'s\x1ft\x1fg1' 1 g2 → $'s\x1ft\x1fg1,g2'`
- 예: `s t '' 0 '' → ""`

### scv_graft_notice
- 역할: Graft 상태와 지원 파일 수를 보고 안내 한 줄을 낸다 — 해당 없으면 빈 값
- 위치: scripts/lib/graft.sh · @pure · sh
- 예: `no-graph 5 → "Graft 는 있지만 이 저장소에 그래프가 없습니다 — 만들면 계획·구현 헤더에 관련 코드 후보가 붙습니다 (지원 언어 파일 5개). 실행: graft init --no-hooks --no-statusline"`
- 예: `ready 5 → ""`
- 예: `absent 0 → ""`

### scv_graft_render_ask
- 역할: ask 후보 줄들을 사람이 읽을 줄들로 풀어 쓴다 — 없으면 "(후보 없음)"
- 위치: scripts/lib/graft.sh · @pure · sh
- 예: `$'a.py:3\x1ffoo' → "  a.py:3 — foo"`
- 예: `'' → "  (후보 없음)"`

### scv_graft_render_blast
- 역할: blast 요약 레코드를 사람이 읽을 줄들로 풀어 쓴다
- 위치: scripts/lib/graft.sh · @pure · sh
- 예: `$'3\x1f5\x1fa.py' → $'  닿는 파일 3 · 심볼 5\n  상위: a.py'`
- 예: `$'?\x1f?\x1f12B' → "  요약 불가 — 원문 12B"`

### scv_graph_build
- 역할: links · touches · refs · 존재 목록 · 문서 목록으로 graph.json 한 줄(노드 · 링크 · 군집 · god_nodes)을 만든다 (jq 필요)
- 위치: scripts/lib/graph.sh · @deterministic · sh
- 예: `"" "" "" x.sh x.sh g t → '{"version":1,"built_at":"t","sources":{"docs":"g","plans":0,"decisions":0},"nodes":[{"id":"x.sh","kind":"doc","community":".","degree":0,"label":"x.sh"}],"links":[],"god_nodes":["x.sh"],"communities":{".":["x.sh"]}}'`

### scv_graph_impact
- 역할: graph.json 에서 경로마다 함께 바뀐 파일 · 계획 · 결정 · 문서를 조회해 text 블록이나 json 으로 낸다 (jq 필요)
- 위치: scripts/lib/graph.sh · @deterministic · sh
- 예: `'{"nodes":[],"links":[]}' text zzz.sh → "▸ zzz.sh — 근거 없음"`
- 예: `'{"nodes":[{"id":"a.sh"}],"links":[{"source":"p1","target":"a.sh","kind":"touches"}]}' json a.sh → '[{"path":"a.sh","known":true,"cochange":[],"plans":[],"docs":[],"decisions":[]}]'`

### scv_graph_report
- 역할: graph.json 텍스트를 GRAPH_REPORT.md 마크다운(출처 · 군집 · god node · 동시변경 · 없는 경로)으로 만든다 (jq 필요)
- 위치: scripts/lib/graph.sh · @deterministic · sh
- 예: `'{"built_at":"t","sources":{"docs":"d","plans":0,"decisions":0},"nodes":[],"links":[],"god_nodes":[],"communities":{}}' → $'# SCV graph report\n\nBuilt: t · nodes 0 · links 0\n\n## Sources\n\n- docs: d\n- plans: 0 · decisions: 0\n\n## Communities\n\n\n## God Nodes\n\n\n## Co-change pairs\n\n\n## Missing paths\n\n- (none)'`

### scv_hstate_brief_line
- 역할: 진단이 안 바뀐 턴에 진단 전체 대신 싣는 한 줄 알림을 만든다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `09:30 → "[SCV preflight] 진단 변동 없음 — 마지막 전체 진단 09:30 과 같다 (바뀌면 전체가 다시 실린다)."`

### scv_hstate_render
- 역할: \x1f 로 구분한 상태를 표식 JSON 한 줄로 만든다
- 위치: scripts/lib/help-state.sh · @pure · sh
- 예: `$'s1\x1f1\x1f3\x1fab12\x1f09:30\x1fdeadbeef' → '{"session":"s1","protocol":1,"turn":3,"diag":"ab12","diag_at":"09:30","nonce":"deadbeef"}'`

### scv_lang_fix_note
- 역할: 다른 언어 줄 수와 자리(중간 · 최종), 걸린 줄 하나를 받아 언어 이름을 넣은 교정 문구를 만든다
- 위치: scripts/lib/lang-enforce.sh · @pure · sh
- 예: `korean 3 mid → "[SCV 언어] 방금 쓴 글 중 3줄이 한국어가 아니다 — 다음 글부터 한국어로 써라(중간 보고 포함)."`
- 예: `korean 2 final → "[SCV 언어] 최종 답 중 2줄이 한국어가 아니다 — 그 줄만 한국어로 고쳐 다시 써라."`
- 예: `korean 1 mid "Next I'll run the tests." → "[SCV 언어] 방금 쓴 글 중 1줄이 한국어가 아니다(예: “Next I'll run the tests.”) — 다음 글부터 한국어로 써라(중간 보고 포함)."`
- 예: `korean 0 mid → ""`

### scv_lang_rule_line
- 역할: 설정 언어로 쓴 언어 규칙 한 줄을 만든다 — 중간 보고까지 그 언어로 쓰라는 줄
- 위치: scripts/lib/lang-enforce.sh · @pure · sh
- 예: `korean → "[SCV 언어] 사용자에게 보이는 글은 모두 한국어로 — 도구 사이 중간 보고 · 요약 포함(파일 · 코드 · 이름은 제 규칙대로). 다른 언어로 쓴 최종 답은 막힌다. 사용자가 이 턴에 다른 언어를 요청하면 그 언어."`
- 예: `english → ""`
- 예: `"" → ""`

### scv_mp_checklist_merge
- 역할: 공통 목록과 모델 목록을 "id\tlabel" 줄로 합친다(같은 id 는 모델 쪽 label 이 이긴다)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `$'a\tA\nb\tB' $'b\tB2\nc\tC' → $'a\tA\nb\tB2\nc\tC\n'`
- 예: `$'# c\nBad\tX' '' → ""`

### scv_mp_first_turn_lines
- 역할: 새 컨텍스트 첫 턴에 실을 가이드 안내 블록을 만든다(싣지 않으면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `on 0 0 $'m-1\nGUIDE_FILE: g.md' → $'[SCV 가이드] 이 컨텍스트에서 아직 이 모델의 프롬프팅 가이드 원문을 읽지 않았다 — 답하기 전에 아래 원문을 끝까지 읽고 아래 명령을 실행하라(지난 모델 m-1 기준 — 지금 모델이 다르면 help 의 GUIDE 줄을 따르라).\n  GUIDE_FILE: g.md\n'`
- 예: `on 1 0 "" → ""`

### scv_mp_gate_reason
- 역할: 편집 거절 판정에 맞는 사유 한 줄을 만든다(ok 면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `answered tok1 x.sh m s1 → $'SCV 프롬프트: 마지막 등록 뒤에 선택 창 답이 왔다 — 편집 전에 다시 등록하라. 범위가 바뀌었으면 bash "x.sh" register --model "m" --session "s1" (전체 다시), 그대로면 bash "x.sh" register --keep --session "s1" (한 줄). 그다음 다시 시도하라.'`
- 예: `ok tok1 → ""`

### scv_mp_gate_reason_sub
- 역할: 하위 에이전트의 쓰기를 거절하는 사유 한 줄을 만든다(answered · forbidden 이 아니면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `forbidden "읽기만" → "SCV 프롬프트(하위 에이전트): 이 세션의 마지막 등록의 범위(scope) 칸이 변경을 막는다('읽기만') — 하위 에이전트는 등록하지 않는다. 이 편집은 하지 말고 리드에게 돌려보내라(범위가 바뀌었으면 리드가 다시 등록한다)."`
- 예: `ok "" → ""`

### scv_mp_guide_lines
- 역할: 결정 · 키 · 경로 · 경과 일수로 help 의 GUIDE 출력 줄들을 만든다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `load k1 m.md c.md 5 90 "" "" → $'GUIDE: load k1\nGUIDE_FILE: m.md\nGUIDE_FILE: c.md\n'`
- 예: `loaded k1 "" "" 100 90 r.sh "" → $'GUIDE: loaded k1\nGUIDE_STALE: 100 days old (limit 90) — refresh: bash "r.sh"\n'`
- 예: `none → $'GUIDE: none\n'`

### scv_mp_guides_candidates
- 역할: 가이드 폴더 후보 경로들을 한 줄씩 낸다(절대 경로면 하나, 상대면 위로 세 단계까지)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `/r /abs → $'/abs\n'`
- 예: `/r prompting → $'/r/prompting\n/r/../prompting\n/r/../../prompting\n/r/../../../prompting\n'`

### scv_mp_help_reason
- 역할: help 를 부르기 전 도구를 거절할 때 쓸 이유 한 줄을 만든다(부를 액션 이름 포함)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `action:help → "[SCV help 먼저] 이 턴은 아직 help 를 부르지 않았다 — 지금 action:help 를 이 턴 메시지 전문을 인자로 불러라. 그 전에는 다른 도구(등록 포함)가 거절된다."`
- 예: `"" → "[SCV help 먼저] 이 턴은 아직 help 를 부르지 않았다 — 지금 SCV 의 help 를 이 턴 메시지 전문을 인자로 불러라. 그 전에는 다른 도구(등록 포함)가 거절된다."`

### scv_mp_principle_candidates
- 역할: 코어 루트로 원칙 파일 후보 경로 두 개를 한 줄씩 낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `/core → $'/core/contracts/rewrite-principle.md\n/core/vendor/scv-core/core/contracts/rewrite-principle.md\n'`
- 예: `/core rewrite-ste.md → $'/core/contracts/rewrite-ste.md\n/core/vendor/scv-core/core/contracts/rewrite-ste.md\n'`
- 예: `"" → ""`

### scv_mp_principle_reason
- 역할: 문제 표를 넣어 막힐 때 모델에게 주는 원칙 요지 한 줄을 낸다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `→ "[SCV 원칙] 답에 문제 표나 '생길 수 있는 문제' 칸을 넣었다 — 문제는 보여 주지 말고 해결책 안에서 막아 다시 써라: '단위 | 해결책 | 추천' 세 칸, 방법마다 그 방법이 부를 문제를 막는 길을 담고, 정할 것은 선택지로 묻고, 남는 한계는 추천 칸 이유에 한 줄(contracts/rewrite-principle.md)."`

### scv_mp_rewrite_tagged
- 역할: 다시 쓴 요청 뒤에 표식을 붙인 REWRITE 줄 값을 만든다(off · 표식 없음이면 요청 그대로)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"요청" on "[P]" → "요청 [P]"`
- 예: `"요청" off "[P]" → "요청"`

### scv_mp_speaker_label
- 역할: 대화 기록의 모델 id 로 저널 화자 이름("assistant · id")을 만든다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `"claude-x-4[1m]" → "assistant · claude-x-4[1m]"`
- 예: `"a b!" → "assistant · ab"`
- 예: `"" → "assistant"`

### scv_mp_stop_reason
- 역할: 종료를 막는 이유 한 줄을 만든다(빠진 쪽을 이름으로 말한다)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `1 1 0 tok1 x.sh m s1 → "다시 쓴 요청 인용이 답 맨 위에 없다 — '> **다시 쓴 요청**: …'(REWRITE 줄 그대로)을 답의 첫 줄로 옮겨라."`
- 예: `1 0 0 tok1 x.sh m s1 → "이번 턴에 등록한 다시 쓴 요청을 답에 보이지 않았다 — 답 맨 위에 '> **다시 쓴 요청**: …'(REWRITE 줄 그대로)을 인용으로 보여라."`

### scv_mp_turn_block
- 역할: 매 턴 훅이 싣는 "1:1 비교 · 등록" 지시 블록을 만든다(스위치 off · 토큰 없음이면 빈 값)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `on tok1 m-1 "" x.sh → $'[SCV 프롬프트] help 를 부른 뒤, 이 턴 메시지(짧아도)를 모델 가이드 요구 항목과 1:1 비교 · 등록한 뒤 일하라 — 등록 전 파일 쓰기는 거절, 등록 · 인용 없는 종료는 차단. 선택 창 답 뒤 첫 편집 전에 다시 등록(범위 그대로면 register --keep).\n  항목마다 msg · ctx(출처) · na(이유) · asked(못 찾은 것 중 가장 영향 큰 하나만, 추천 답과 함께) → bash "x.sh" register --model "m-1" (stdin "id | 상태 | 값" 줄들 + "rewrite | - | 다시 쓴 요청"; 파일을 안 바꾸는 턴은 scope 값을 \'변경 없음 — …\' 으로 시작) → 답 맨 위에 \'> **다시 쓴 요청**: …\' 전문 인용(ctx · asked 항목 표시), 그 아래 굵은 주제 + 개조식 불릿(contracts/writing.md), 그것으로 일한다.\n  항목: bash "x.sh" checklist --model "{지금 모델 id}"\n'`
- 예: `off tok1 → ""`

### scv_mp_turn_dir
- 역할: 저널 폴더와 세션 이름으로 이번 턴 상태 폴더 경로를 만든다(이름이 비면 저널 폴더)
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `scv/journal sess-1 → "scv/journal/.help-turns/sess-1"`
- 예: `scv/journal "" → "scv/journal"`

### scv_mp_warn_lines
- 역할: 판정 줄들을 다음 턴에 실을 경고 문장으로 바꾼다
- 위치: scripts/lib/model-prompting.sh · @pure · sh
- 예: `unshown k1 → $'[SCV 가이드] 직전 턴에 다시 쓴 요청을 기록만 하고 답에 보이지 않았다 — 이번 턴에는 답 맨 위에 전문을 인용으로 보여라.\n'`
- 예: `"" → ""`

### scv_mx_render_models
- 역할: 모델별 답 수 줄들을 표의 "모델별 답 수" 한 줄로 만든다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'m1\t2\n-\t1\n' → "모델별 답 수 | m1 2 · 표기 없음 1 | 2/3 | —"`
- 예: `"" → "모델별 답 수 | — | 0/0 | —"`

### scv_mx_render_table
- 역할: 네 요약 줄(턴 · 리드타임 · 후속 · 순수)을 파이프 구분 지표 표로 만든다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `$'1\t2\t3\t30\t30' $'1\t1\t5\t50\t50' $'1\t2\t1\t\t' $'1\t2\t1\t\t' → $'지표 | 값 | 적용 범위 | 중앙값\n계획당 대화 턴 수 | 평균 3.0 | 1/2 | 3.0\n승인→보관 리드타임(분) | 평균 5.0 | 1/1 | 5.0\n후속 재발률 | 1/2 | 1/2 | —\n순수 절 보유율 | 1/2 | 1/2 | —'`

### scv_mx_render_tsv
- 역할: 지표 이름과 지표 줄들을 (지표, slug, 값) TSV 행들로 만든다
- 위치: scripts/lib/metrics.sh · @pure · sh
- 예: `lead $'a\t5\nb\tnone\n' → $'lead\ta\t5\nlead\tb\tnone'`

### scv_plan_history_add
- 역할: PLAN.md 글의 `## 변경 이력` 절 끝에 사건 하나를 붙인다 — 첫 줄은 "- " 항목, 나머지 줄은 "  - " 하위 항목, 사건 사이는 빈 줄. 절이 없으면 `## Links` 앞(없으면 글 끝)에 새로 만든다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'# a\n\n## 변경 이력\n\n- 1\n\n## Links\n' $'2\n이유: x' → $'# a\n\n## 변경 이력\n\n- 1\n\n- 2\n  - 이유: x\n\n## Links\n'`
- 예: `$'# a\n\n## Links\n' "1" → $'# a\n\n## 변경 이력\n\n- 1\n\n## Links\n'`
- 예: `"# a" "1" → $'# a\n\n## 변경 이력\n\n- 1'`

### scv_plan_redo_step
- 역할: 끝난 단계 n 의 요건이 바뀌었을 때 맨 끝에 붙일 "다시 하기" 단계 글을 만든다 — 원래 단계의 " — " 뒤 꼬리는 그대로 둔다
- 위치: scripts/lib/plan-link.sh · @pure · sh
- 예: `$'## Suggested path\n1. [x] 검사 추가 — `checkA`\n2. b' 1 → $'다시 하기: 검사 추가 — `checkA`'`
- 예: `$'## Suggested path\n1. [x] 준비' 1 → "다시 하기: 준비 — 1단계를 바뀐 요건으로 다시 함"`
- 예: `$'## Suggested path\n1. a' 3 → ""`

### scv_resume_header
- 역할: 컨텍스트가 비워진 이유 한 줄 머리말을 만든다 — source 값이 있으면 그대로 보여 주고 없으면 일반 문구
- 위치: scripts/lib/resume-recap.sh · @pure · sh
- 예: `clear → $'[SCV resume] The context was just reset (source: clear). Nothing was lost — below is what this project was in the\nmiddle of: active plans, recent decisions, and the active conversation. Continue\nfrom here instead of asking the user to repeat themselves. Switch:\nscv/scv_settings.json SCV_RESUME_RECAP=off.'`
- 예: `'' → $'[SCV resume] The context was just reset. Nothing was lost — below is what this project was in the\nmiddle of: active plans, recent decisions, and the active conversation. Continue\nfrom here instead of asking the user to repeat themselves. Switch:\nscv/scv_settings.json SCV_RESUME_RECAP=off.'`

### scv_show_real_excerpts
- 역할: 애매한 턴 줄마다 보인 출력과 끝 글 마지막 1,500자를 판정자에게 보일 한 줄 발췌로 만든다
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `$'s1\t2026-10-01T01:00:00Z\tb\t5 passed\tAll 5 passed.' → $'s1\t2026-10-01T01:00:00Z\tb\t[Shown output] 5 passed\x1e[Final message]\x1eAll 5 passed.'`

### scv_show_real_judge_prompt
- 역할: 물을 턴 줄들로 판정자에게 보낼 질문 글을 만든다
- 위치: scripts/lib/show-real.sh · @deterministic · sh
- 예: `$'Q\tk1\ts1\tt\tb\tx' → $'You judge excerpts from an AI coding assistant\'s work log. Answer with one JSON array only.\n\nBelow are 1 excerpts. Each comes from one turn in which the assistant edited files, ran something, and showed part of the run\'s actual output to the user. [Shown output] is an output line the assistant showed; [Final message] is the end of the assistant\'s last message in that turn.\n\nQuestion: in each turn, after showing the actual result, did the assistant ask the user whether to continue or what to fix? Asking can be a choice window or a text question. Even without a question mark, it counts as asking when the assistant asks the user to look at this result and say whether to continue or what to change (e.g. "리뷰 부탁드립니다" / "Please review", "고칠 점이 있으면 알려 주세요" / "Let me know anything to fix", "검토 후 ship it 이면 끝냅니다" / "If it is a ship it after review, I am done"). It does not count when the assistant only reports that the work is done, only says it is waiting for someone\'s review, announces what it will do next, or offers a separate follow-up task (e.g. "다음 작업으로 계획할지는 말씀해 주시면 됩니다" / "Tell me if you want these planned as the next task").\n\nAnswer with one JSON array of 1 items only — "yes" or "no" for each excerpt, in order.\n\n=== Excerpt 1 ===\nx'`

### scv_show_real_pct
- 역할: 부분과 전체로 "N% (부분)" 글을 만든다(전체가 0 이면 "- (부분)")
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `3 4 → '75% (3)'`
- 예: `0 0 → '- (0)'`

### scv_show_real_per
- 역할: 합과 세션 수로 세션당 값 "A.BC (합)" 글을 만든다(세션이 0 이면 "- (합)")
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `5 2 → '2.50 (5)'`
- 예: `5 0 → '- (5)'`

### scv_show_real_render
- 역할: 셈 두 줄과 언어 · 기간 · 파일 수로 켜기 전 · 켠 뒤 비교 표와 범례를 만든다(숫자와 날짜만)
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'before\t2\t10\t4\t2\t1\t3\nafter\t2\t12\t6\t5\t0\t1' en 2026-09-01..2026-09-30 2026-10-01..2026-10-31 4 0 → $'Show the real thing — real-use report (before · after)\n\n| Period | Sessions | Changed turns | (a) Shown | (b) Fixes/session | (c) Asks/session |\n|---|---|---|---|---|---|\n| Before 2026-09-01..2026-09-30 | 2 | 4 | 50% (2) | 0.50 (1) | 1.50 (3) |\n| After 2026-10-01..2026-10-31 | 2 | 6 | 83% (5) | 0.00 (0) | 0.50 (1) |\n\n(a) Share of changed turns with \'edit → run → the result shown, then a continue-or-fix ask\' (in brackets: turns)\n(b) First answered person message after a completion report that asks for a fix, per session (in brackets: total)\n(c) Choice windows + turn-ending text questions, per session (in brackets: total)\nThe numbers show direction only — the two periods may hold different kinds of work. Counting rules: header of core/scripts/lib/show-real.sh.\nSession record files read: 4'`

### scv_show_real_rule
- 역할: 실체 보여 주기 켬 여부와 통로로 매 턴 블록에 덧붙일 안내 세 줄을 만든다(off 면 빈 값)
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `off text → ""`
- 예: `on none → $'[SCV 실체 보여 주기] 결과물이 바뀌는 일이면 처음 돌아가는 순간에 가장 작은 것을 실제로 실행해\n그 결과(출력 · 화면)를 보고에 그대로 남겨라 — 사람이 없는 실행이나 자동 알림 턴이라 묻지 않는다. 설명은 한두 줄로.\n결과물이 바뀌지 않는 일은 보여 주지도 묻지도 말고 \'결과물 변화 없음\'이라고 적어라. 본문: contracts/show-real.md'`

### scv_show_real_zip
- 역할: 물을 턴 줄들과 판정자 답 줄들을 짝지어 A 줄(yes · no · unjudged)로 만든다
- 위치: scripts/lib/show-real.sh · @pure · sh
- 예: `$'Q\tk1\ts1\tt\tb\tx' yes → $'A\tk1\ts1\tt\tb\tyes'`
- 예: `$'Q\tk1\ts1\tt\tb\tx' '' → $'A\tk1\ts1\tt\tb\tunjudged'`

### scv_step_line
- 역할: 단계 보고 도구 이름과 구현 중인 계획 이름으로 매 턴 안내 한 줄을 만든다 — 둘 중 하나라도 비면 아무것도 내지 않는다
- 위치: scripts/lib/step-report.sh · @pure · sh
- 예: `"demo_step" "20260102-a-y" → "[SCV 단계] 구현 중: 20260102-a-y — 이 세션에 demo_step 도구가 있으면, 단계를 시작할 때 · 끝낼 때 · 막혔을 때(이유 한 줄) 바로 알려라(plan=20260102-a-y, step=번호, state=doing|done|blocked). 본문: protocols/work.md 'Step progress'"`
- 예: `"" "20260102-a-y" → ""`
- 예: `"demo_step" "" → ""`

### scv_tc_block_msg
- 역할: 막을 때 모델에게 줄 말을 만든다 — 무엇이 빠졌는지와 할 일 한 줄(명령 꼴 그대로)
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"in-plan" "a" 3 "/p/plan-link.sh" → $'[SCV 계획 기록] 이번 턴에 파일 3개가 바뀌었는데 계획 기록이 없다 — 계획 안 일이면: bash /p/plan-link.sh progress a --step 번호 --state doing --note "한 일" (단계가 끝났을 때만 --state done)\n계획 밖 일이면: bash /p/plan-link.sh append a --after 번호 --step "단계" --why "이유"'`
- 예: `"no-plan" "" 1 "/p/plan-link.sh" → $'[SCV 계획 기록] 이번 턴에 파일 1개가 바뀌었는데 진행 중 계획이 없다 — 계획을 만들어라(promote). 릴리스 · 동기화만 예외: bash /p/plan-link.sh exempt --kind release --why "이유"'`
- 예: `"step" "tool_x" 2 "/p/plan-link.sh" → "[SCV 단계 보고] 대시보드가 켜져 있다 — 이번 턴에 한 단계를 tool_x 로 알려라(시작 · 끝 · 막힘)."`
- 예: `"return" "b" 2 "/p/plan-link.sh" → "[SCV 되돌아가기] 계획 b 가 끝났는데 그것 때문에 보류한 계획이 아직 보류다 — bash /p/plan-link.sh resume b"`

### scv_tc_choice_entry
- 역할: 선택 답 한 개를 계획 변경 이력 항목으로 만든다 — 답이 머리, 질문이 아래(각 120자)
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"2026-11-09" "10:24" "어떻게 할까요?" "추천대로" → $'**2026-11-09 10:24 선택** — 답: 추천대로\n질문: 어떻게 할까요?'`
- 예: `"2026-11-09" "10:24" $'두\n줄' "a" → $'**2026-11-09 10:24 선택** — 답: a\n질문: 두 줄'`

### scv_tc_exempt_entry
- 역할: 예외 기록 한 줄(이력 항목)을 만든다 — 종류 · 이유 + 요청 꼬리
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"2026-11-09" "release" "래퍼 0.86.0" "요청: x (요청 ab12cd34)" → $'**2026-11-09 예외** — release: 래퍼 0.86.0\n요청: x (요청 ab12cd34)'`

### scv_tc_progress_entry
- 역할: 계획 안 일의 진행 한 줄(이력 항목)을 만든다 — 머리 줄(단계 · 시작/끝/막힘) + 요청 꼬리. 대시보드가 이 줄로 단계 상태를 센다. 상태를 안 주면 시작(0.87.4 — 끝은 직접 말할 때만)
- 위치: scripts/lib/turn-check.sh · @pure · sh
- 예: `"2026-11-09" 6 done "2인 적 배수" "요청: x (요청 ab12cd34)" → $'**2026-11-09 진행** — 6단계 끝: 2인 적 배수\n요청: x (요청 ab12cd34)'`
- 예: `"2026-11-09" 1 doing "준비" "" → "**2026-11-09 진행** — 1단계 시작: 준비"`
- 예: `"2026-11-09" 1 "" "측정 중" "" → "**2026-11-09 진행** — 1단계 시작: 측정 중"`
- 예: `"2026-11-09" 2 blocked "키 없음" "" → "**2026-11-09 진행** — 2단계 막힘: 키 없음"`
