# 옛 자료 21건 검토표 — README 최신화 계획

`readpath.sh outdated` 가 2026-09-30 에 OUTDATED-CANDIDATE 로 표시한 사용이 끝난 자료 21건(PLAN.md 부록 A)을 지금 코드와
대조했다. 자료 본문은 고치지 않았다 — 판정은 이 표에만 남긴다.

## 판정 기준

- **유효** — 자료의 결정 · 설계, 그리고 지금도 참이어야 하는 주장이 지금 코드와 맞는다.
- **일부 낡음** — 그런 주장 가운데 지금 코드와 맞지 않는 것이 있다(무엇인지 근거에 적는다).
- **대체됨** — 뒤에 보관된 계획이 자료의 접근을 바꿨다(그 계획 slug 를 적는다).
- 자료의 문제 서술 · 실측(자료를 소비한 계획이 고치려던 그때 상태)은 역사로 보고 판정에 넣지 않는다. 세 검토자 가운데
  둘은 이 부분까지 셌는데, 이 기준으로 맞추면 1번만 판정이 바뀐다(일부 낡음 → 유효 — 적힌 문제 1~3 은 그 자료를 쓴 계획이
  고친 것이고, 나머지 주장은 그대로 맞다).

## 결과 — 유효 8 · 일부 낡음 12 · 대체됨 1

| 번호 | 자료 | 가리키는 바뀐 파일(주요) | 판정 | 근거 |
|---|---|---|---|---|
| 1 | scv/raw/stale/20260812-wookiya1364-ci-provenance-gate.md | .github/workflows/branch-flow.yml · core-ci.yml · promote.yml, core/scripts/check-frontmatter.sh, core/protocols/work.md, core/tests/run-dry.sh | 유효 | "게이트가 없다 · check-frontmatter 가 저장소 자체에 안 돈다 · glob 이 promote/ 뿐"은 이 자료를 쓴 계획이 구현해 더는 사실이 아님(branch-flow.yml:22-28, core-ci.yml:77-82, check-frontmatter.sh:126). 9b 보관 → 9d PR 순서(work.md:420, :591)와 lib/yaml.sh 의 flow/block 처리는 그대로 |
| 2 | scv/raw/stale/20260812-wookiya1364-forced-invocation.md | core/protocols/{help,promote,work,routine,sync}.md, core/scripts/work.sh, core/template/scv/*, core/integrations/loop-runner.md, docs/wrapper-integration.md | 일부 낡음 | `.env` 쓰기용 env-set.sh 는 20260823-wookiya1364-settings-json 에서 삭제 — 지금은 settings-set.sh(guard.md:143-146). 적힌 file:line 목록은 더는 그 문구를 가리키지 않음(예외는 문구로 고정, guard.md:148-163). 15개 액션 영수증 발급(guard.md:62-83)은 그대로 |
| 3 | scv/raw/stale/20260813-wookiya1364-deck-redesign.md | core/DeckUI/scripts/deckdoc/static-mermaid.mjs, core/protocols/deck.md, core/protocols/promote.md | 일부 낡음 | "id 를 scv-mmd-1 로 고정"은 20260828-wookiya1364-deck-mermaid-id-collision 이 내용 해시 id 로 바꿈(static-mermaid.mjs:211-227). 다크 %%{init} 지시(promote.md:593-597), 정규화 1·2·4단계는 그대로. "인라인 색 제거를 deck.md 에 적는다"는 반영된 적 없음 |
| 4 | scv/raw/stale/20260814-wookiya1364-release-machinery.md | .github/workflows/promote.yml, core/scripts/check-provenance.sh | 유효 | promote.yml:66-137 이 적힌 대로(세 조건, DIRTY/DRAFT 중단, BEHIND update-branch, UNKNOWN 대기) — test-promote-wait.sh 13/13. check-vendor-provenance.sh:54-64 의 [manual-vendor: 이유] · 빈 표지 거부 — test-provenance-gates.sh 19/19 |
| 5 | scv/raw/stale/20260818-wookiya1364-effort-governor.md | core/protocols/work.md, core/protocols/codegen.md, core/scripts/effort-class.sh | 일부 낡음 | 모드 설정 위치가 `.env` → scv/scv_settings.json(work.md:250), `.env.example.scv` 는 20260823-wookiya1364-settings-json 이 삭제. effort-class.sh 의 R0–R3 · armed, Step 5e 정책은 그대로. haiku 라우팅은 20260903-session-model-default 가 없앰 |
| 6 | scv/raw/stale/20260818-wookiya1364-env-example-sync.md | core/scripts/sync.sh, core/scripts/hydrate.sh, core/scripts/lib/scvroot.sh | 대체됨 | 20260823-wookiya1364-settings-json 이 `.env.example.scv` · sync 의 overwrite 분기를 삭제(sync.sh:372-376 주석만 남음). 새 키 전파는 20260824-wookiya1364-settings-always-present 가 이어받음(scvroot.sh:205-216) |
| 7 | scv/raw/stale/20260818-wookiya1364-regression-contract-repair.md | core/protocols/work.md, core/scripts/{status,tests-smell}.sh, core/template/scv/PROMOTE.md, core/tests/test-provenance-gates.sh, tests/test-guard-consistency.sh | 유효 | 재발 방지 두 가지가 있음(PROMOTE.md:514-520, tests-smell.sh:56-80). 옛 4건 모두 obsolete · obsoleted_by 가 이 슬러그. 보수 계약 T2–T4 재실행 통과 |
| 8 | scv/raw/stale/20260818-wookiya1364-regression-runner-env-leak.md | core/scripts/regression.sh, core/scripts/lib/scvroot.sh, core/tests/test-autosync.sh (fixture DECISIONS.md 는 이름만 같은 오탐) | 유효 | scv_autosync 의 플래그 확인과 SCV_AUTOSYNC_RUNNING 내보내기 순서(scvroot.sh:137·147), run_scenario_clean 의 env -u(regression.sh:352-366). 지우는 목록이 같은 방식으로 넓어졌을 뿐(env.sh:43-51, 20260821-wookiya1364-regression-runner-path-leak · rule-conflicts-followup) |
| 9 | scv/raw/stale/20260818-wookiya1364-sync-autopilot-guard-fixes.md | core/scripts/sync.sh, core/scripts/lib/scvroot.sh, core/protocols/update.md · sync.md, core/template/hooks/guard.sh, core/contracts/guard.md, core/tests/test-guard.sh | 일부 낡음 | 더티 판정이 git status 가 아니라 HEAD 내용 비교(sync.sh:206-239), 스탬프는 거부 0건일 때만 전진(sync.sh:504-526). 자동 갱신 판단이 지문 + 번호로 바뀜(scvroot.sh:175-179, 20260823-wookiya1364-template-refresh). 백업 제거 · --force · cmp 선검사, 영수증 저장소 실패 알림(guard.sh:122-128)은 그대로 |
| 10 | scv/raw/stale/20260824-wookiya1364-regression-contract-repair-2.md | core/tests/test-autosync.sh, core/tests/test-settings.sh | 유효 | 적힌 실제 이름 4개(test-settings.sh · test-template-digest.sh · test-autosync.sh · tests/run.sh)가 모두 있고 틀린 이름은 없음. 옛 계약 6건의 obsolete frontmatter 확인. "7건"과 달리 path-leak 은 계획 단계에서 살려 둠(repair-2 PLAN.md:20) — 코드 주장과 무관 |
| 11 | scv/raw/stale/20260824-wookiya1364-settings-always-present.md | core/scripts/settings-migrate.sh, scv/scv_settings.json | 유효 | 액션 시작 때 settings_ensure(scvroot.sh:205-217, settings.sh:355-389), 비밀 파일은 git 무시 확인 뒤에만(settings.sh:343-353), settings-migrate.sh 는 settings_ensure 별칭(:36-38). 이 저장소는 수화 전이라 적용 범위 밖일 뿐 규칙은 그대로 |
| 12 | scv/raw/stale/20260826-wookiya1364-deck-density.md | core/protocols/deck.md (fixture PLAN.md 는 오탐) | 일부 낡음 | "밀도 지표가 없다" → 그림 0개 경고가 생김(transform.mjs:390-398). "PLAN.md 가 deck 의 주 입력" → 본문은 FEATURE_ARCHITECTURE.md(deck.md:71 · 142-148, 20260827-wookiya1364-deck-picture-only). 어절 수 상한 · 화살표 산문 감지는 여전히 없음 |
| 13 | scv/raw/stale/20260826-wookiya1364-deck-screen-spec-format.md | scv/archive/20260826-wookiya1364-numbered-spec-deck/FEATURE_ARCHITECTURE.md, scv/raw/stale/20260826-wookiya1364-deck-density.md (둘 다 이름만 같은 매칭) | 유효 | 양식이 구현됨: PAGE CODE, 번호 · 문자 마커, 상태, 검증 문구 표(i18n.mjs:45-60, transform.mjs:101-150, render.mjs:673). BE 그림의 번호 라벨(transform.mjs:431-443). 샘플 이미지는 scv/raw/stale/ 로 옮겨졌을 뿐 |
| 14 | scv/raw/stale/20260827-wookiya1364-deck-picture-only.md | core/DeckUI/scripts/deckdoc/doc.mjs | 유효 | 기본 본문은 그림 문서, --full 로 셋을 합침(doc.mjs:63 · 77-79 · 122), 그림 문서가 없으면 DECK_SKIPPED 와 exit 0(doc.mjs:159-165), 원문 탭 3개 유지. 자료의 실측표가 지금 보관본과 일치 |
| 15 | scv/raw/stale/20260914-wookiya1364-run-dry-audit.md | core/tests/run-dry.sh, core/template/scv/PROMOTE.md | 일부 낡음 | 감사 수치가 지금과 다름(4,036→4,141줄, 섹션 68→69, assert_contains 453→414 등). 정확히 같은 중복 3개 삭제 · `# why:` 주석 116개 · PROMOTE.md 앵커 31→30(커밋 6349ef7). 보관 계획 run-dry-anchor-diet 가 이 감사를 과대치로 정정(GUIDANCE 전용 80→32, 보관 PLAN.md:142) |
| 16 | scv/raw/stale/20260916-always-on-per-turn-cost-diet.md | core/protocols/help.md, core/protocols/help/full.md, core/scripts/help.sh | 일부 낡음 | 실측값 변화(help.md 9,670→7,199B, "Deep questions" 절은 full.md 로 이동). 상한 변화(BODY 10,000→7,500, FULL 8,000→9,000, TURN 12,000→11,000 — test-help-budget.sh:42-45). 여전히 맞음: [15p] 제약(run-dry.sh:3792~), test-help-shape 가 help.md 고정(test-help-shape.sh:21) |
| 17 | scv/raw/stale/20260916-answer-lint-one-turn-lag.md | core/template/hooks/on-stop.sh | 일부 낡음 | 적힌 추출 방식(tail -n 400 … last)은 옛 코드 — 지금은 last_assistant_message → 이번 턴 원본(250ms×4) → 생략 순(on-stop.sh:78-125). 출처 선택 검사는 test-answer-lint-source.sh. 턴 중간 메시지 관찰(turn=8)의 후속 raw · 계획은 찾지 못함(미해결) |
| 18 | scv/raw/stale/20260916-graft-partial-adoption-shared-conversation.md | core/tests/fixtures/metrics/scv/DECISIONS.md (이름만 같은 오탐) | 일부 낡음 | 표시된 파일은 오탐. 방향(Graft 어댑터 + 자체 그래프)은 graft-adapter · scv-own-graph 로 배송, 연결 위치는 다름(regression.sh:505, work.sh:429-434, promote-helper.sh:88-92). 설치 명령 옵션 차이(lib/graft.sh:44). graphify 는 scv-own-graph 에서 제거 |
| 19 | scv/raw/stale/20260916-graph-dependency-decision.md | core/scripts/work.sh (나머지 3개는 이름만 같은 오탐) | 일부 낡음 | graphify 계약 경로는 사라지고 scv/.graph 사용(work.sh:124-128). "소비처 4곳 안 고침"은 성립 안 함 — 새 경로로 바뀜(promote.md:142, DECISIONS 2026-09-17 08:38). ARCHIVED_AT diff 제안은 미채택(graph.sh:64-73). 결론과 순서는 그대로 실행됨 |
| 20 | scv/raw/stale/20260920-wookiya1364-graft-guidance.md | core/scripts/lib/graft.sh | 일부 낡음 | "먼저 알리는 단계가 없다"는 이제 틀림 — GRAFT_NOTICE(graft.sh:57-59, lib/graft.sh:76-86). "bash 라 빈 결과" 전제도 틀림 — DeckUI JS/TS 29개. codegen 에는 전달 문장 없음(test-graft-adapter.sh:164) |
| 21 | scv/raw/stale/20260920-wookiya1364-regression-runner-lang-leak.md | core/scripts/regression.sh, core/tests/run-dry.sh, core/tests/test-autosync.sh, scv/scv_settings.json | 일부 낡음 | 여전히 맞음: 설정 키를 SCV_ENV_LOADED_KEYS 에 적고 자식 검사에서 지움(lib/env.sh:32-37, regression.sh:362), T9w 형제 저장소 참조(test-autosync.sh:314-333). 낡음: "남은 것 — pr-helper 재실행 누출"은 해결됨(env_settings_unset_args → lib/env.sh:48, pr-helper.sh:255, rule-conflicts-followup) |

## 함께 드러난 것

- **이름만 같은 파일로 생긴 오탐** — 1 · 2 · 5 · 7 · 8 · 9 · 12 · 13 · 14 · 18 · 19번의 표시 가운데 일부는 `PLAN.md` ·
  `DECISIONS.md` · `TESTS.md` · `ARCHIVED_AT.md` · `FEATURE_ARCHITECTURE.md` · `README.md` 처럼 이름만 같은 다른
  파일(검사 fixture, 다른 계획의 문서)이 바뀌어 잡힌 것이다. `outdated` 가 전체 경로가 아니라 파일 이름으로 맞추기 때문으로
  보인다 — 후속 개선 후보(전체 경로 일치), 이 계획의 범위 밖.
- **확인하지 못한 것** — 검토는 읽기 전용이었다. 테스트는 일부만 돌렸고(4번: test-promote-wait 13/13 · test-provenance-gates
  19/19, 7번: 보수 계약 T2–T4), 다른 저장소에 관한 주장(1번 확인 6, 2번 확인 9 일부)과 21번의 "SCV_LANG=korean 이면 run-dry
  2건 실패", 16번의 래퍼 쪽 help SKILL.md 크기, 18번의 Graft 저장소 주소(trailhq/Graft 와 코드의 nanonets/graft)는
  재현 · 확인하지 않았다.

## 다시 사용 표시

21건 모두 검토를 마쳤으므로 이 계획 slug 로 `readpath.sh consume` 한다 — 자료는 옮기지 않고(이미 stale/) slug 를 덧붙이며
ref_commit 을 지금 HEAD 로 다시 찍는다. 그 뒤 `readpath.sh outdated` 는 이 21건을 다시 표시하지 않는다(가리키는 파일이
다시 바뀌기 전까지).
