---
slug: readme-refresh-core-wrappers
started_at: 2026-09-30T00:21:43+09:00
status: archived
archived_at: 2026-09-30T10:41:34+09:00
promoted_to: scv/archive/20260930-wookiya1364-readme-refresh-core-wrappers/
---

## Turn 1 — 2026-09-30T00:21:43+09:00
protocol: b0db83c0

**User**: 아냐 이건 둬도 되는데, 리드미가 지금 만들어진것과 차이가 꽤클거같아서, 최신화가 필요해. 코어랑 래퍼두개 모두말이야

**다시 쓴 요청**: 코어 · 클로드 래퍼 · 코덱스 래퍼 세 저장소의 README 가 지금 기능과 얼마나 다른지 먼저 조사해 차이를 보여 주고, 최신화 범위(언어판 · 깊이 · 배포 방법)를 정할 결정을 추천과 함께 묻는다. 수정은 계획 승인 뒤에 한다. (적용한 가이드 규칙: best-practices "Be clear and direct", best-practices "Minimizing hallucinations in agentic coding", opus-5-5 "say plainly what it did, what it found, and what it needs from you")

**Claude Code**: 차이가 크다(확인). 조사 결과:
- 첫 화면 README(영 · 한 · 일) 9개 모두 마지막 수정 2026-08-25, 그 뒤 릴리스 코어 37 · 클로드 33 · 코덱스 31. 코덱스 플러그인 안내 README 3개(52줄)도 같은 시기.
- 명령 목록은 최신: 스킬 15개 모두 두 래퍼 README 에 있음.
- 키워드 검색 기준으로 세 README 모두 없는 것: 모델별 프롬프팅(가이드 원문 · 매 턴 요구 항목 비교 · 등록), 재개 요약(recap), 배경 조사 위임. 코어 README 는 쉬운 말 · 결정 기록(lesson)도 없음. 설정 키 34개 중 README 마다 1개.
- 두 래퍼 README 모두 업데이트 방법이 없음(클로드: 설치 두 줄만, 코덱스: plugin add 만 — 실제로 되는 marketplace upgrade 안내 없음).
- 세 저장소 promote 는 release=false 로 릴리스 없이 main(GitHub 첫 화면)까지 올릴 수 있음.
결정 제안: (1) 범위 = 첫 화면 README 9개 + 코덱스 플러그인 README 3개, 템플릿 · 어댑터 안내문 제외 (2) 깊이 = 구조 유지, 틀린 사실 수정 + 빠진 주요 기능 절 추가, 설정은 자주 쓰는 몇 개 + 설정 예시 파일 연결 (3) 완료 기준 = README 의 명령 · 설정 · 기능이 실제로 있음, 주요 새 기능 누락 없음, 세 언어판 내용 일치 — 검사 스크립트로 확인 (4) 반영 = 코어에 세 저장소 범위 계획 하나, 병합 뒤 release=false 로 main 까지.
관찰(제품): 직전 답의 첫 문단이 세 문장이라 답 모양 검사가 규약 지문을 비웠고, 그 결과 같은 컨텍스트에서 가이드 원문 두 개(약 94KB)를 다시 읽고 표시함 — 비용 면에서 따로 볼 만한 동작.

## Turn 2 — 2026-09-30T00:29:13+09:00
protocol: b0db83c0

**User**: 전부 추천대로

**다시 쓴 요청**: 확정한 네 결정(범위 12개 파일 · 구조 유지 보강 · 검사 스크립트로 완료 확인 · 릴리스 없이 main 반영)으로 세 저장소 README 최신화 계획서 초안을 만들어 승인을 받는다. README 수정은 계획 승인 뒤에 한다. (적용한 가이드 규칙: best-practices "Be clear and direct", opus-5-5 "state the completion condition up front")

**Claude Code**: 네 결정 확정 → /scv:promote 로 넘김(대화 파일이 자료, raw 복사 없음 — 결정 4 가 계획 수립 동의를 포함). 계획 초안 요약: 폴더 20260930-wookiya1364-readme-refresh-core-wrappers, 범위 = 첫 화면 README 9개 + 코덱스 플러그인 README 3개 + 검사 스크립트 하나와 코어 CI 연결. 더할 내용 = 8-25 이후 보관 계획 38개에서 묶은 사용자 기능(매 턴 함께 · 쉬운 말 답 · 재개 요약 · 모델별 가이드 · 배경 조사 · 번호식 기획서 · 자체 그래프와 선택적 Graft · 본문 검색 · 과정 계기판) + 업데이트 방법 + 자주 쓰는 설정. 확인한 제약: 래퍼 README 에는 버전 번호를 안 적음(배지가 읽음, set-wrapper-version 주석), 클로드 README 에 코덱스 문법 금지(계약 검사), 코어 README 는 내보내기로 래퍼 안 코어 사본에도 들어감(다음 코어 릴리스 때 반영), 호스트 중립 검사는 core/ 만 본다. 검사 7개(범위 · 사실 · 기능 누락 · 언어판 일치 · 기존 검사 · 붉은 검사 · main 반영). 물은 것: 초안 승인 / 추가 질문 없음 / 구조도 생략 / 래퍼 CI 연결은 다음 코어 릴리스 뒤 — 모두 추천 포함.

## Turn 3 — 2026-09-30T00:36:49+09:00
protocol: b0db83c0

**User**: 사용이 끝난 옛 자료 21개가 그 뒤에 바뀐 코드를 가리킨다는것도 이번 계획에 포함하자

**다시 쓴 요청**: 사용이 끝난 옛 자료 가운데 그 뒤에 바뀐 코드를 가리키는 21개를 이번 README 계획에 넣는다. 자료마다 지금 코드와 대조해 판정을 남기는 검토를 계획에 더하고, 검토 뒤의 끝 상태는 추천과 함께 묻는다. 자료 본문은 고치지 않는다. (적용한 가이드 규칙: best-practices "Be clear and direct", best-practices "Minimizing hallucinations in agentic coding")

**Claude Code**: 계획에 옛 자료 21개 검토를 더함. 확인한 사실: 경고(readpath outdated)는 "자료가 언급한 파일이 소비 뒤 바뀌었다"는 힌트일 뿐 틀렸다는 뜻이 아님(스크립트 설명: semantic verification 은 호스트 몫). 사용이 끝난 자료는 내용 불변 규칙(readpath 머리말). 이미 stale 에 있는 자료를 다시 consume 하면 slug 가 덧붙고 ref_commit · consumed_at 이 지금 HEAD 로 다시 찍혀(코드 확인: RD_COMMIT[$dest]="$commit") 경고가 꺼진다 — 코드 추가 없이 끌 수 있음. promote 규칙도 사용자가 명시하면 stale 자료를 추가 자료로 쓰고, OUTDATED 면 먼저 대조하라고 함. 순서: 대조 검토 → 검토표 → 검토 마친 자료만 이 계획 slug 로 consume(판정 전에 찍으면 낡음을 가림). 검사 추가: 21개 모두 판정 · 근거, 표시 뒤 경고 목록에서 빠짐. 결정표 5행(초안 승인 · 추가 질문 없음 · 구조도 생략 · 래퍼 CI 는 다음 코어 릴리스 뒤 · 검토 뒤 끝 상태 = 판정 남기고 검토 마친 자료만 다시 사용 표시).

## Turn 4 — 2026-09-30T00:44:42+09:00
protocol: b0db83c0

**User**: 추천대로하고, 4번은 코어 배포되면 래퍼ci연결 진행해

**다시 쓴 요청**: 결정 다섯 가지를 모두 추천대로 반영해 README 최신화 계획서(PLAN.md · TESTS.md)를 만들고 결정 기록을 남긴다. 래퍼 CI 연결은 다음 코어 배포 뒤 이어서 할 후속 단계로 계획에 적어 잊지 않게 한다. README 수정 · 커밋은 하지 않는다. (적용한 가이드 규칙: best-practices "Be clear and direct", opus-5-5 "Unattended agentic runs — keep the task's parts in a checklist")

**Claude Code**: 계획 생성 — scv/promote/20260930-wookiya1364-readme-refresh-core-wrappers/ (PLAN.md · TESTS.md, status planned, lang korean). 범위: README 12개 + tools/check-readme.sh · tests/test-check-readme.sh(코어 CI) + 옛 자료 21건 검토표(STALE_REVIEW.md, 작업 때) + 검토 마친 자료만 consume. 필수 주제 표(표식: SCV_ALWAYS_ON · SCV_PLAIN_LANGUAGE/SCV_ANSWER_LINT · SCV_RESUME_RECAP · SCV_MODEL_PROMPTING · SCV_DELEGATE_EFFORT · SCV_GRAPH/SCV_GRAFT · 기획서 · 본문 검색 · 과정 계기판 · 래퍼 업데이트 방법). TESTS 12개(범위 · 실재 · 주제 · 언어판 · 업데이트 방법 · 버전/문법 · 붉은 검사 · 맥/리눅스 · 기존 검사 · 검토표 · 경고 해제와 본문 불변 · release=false 로 main 반영). 래퍼 CI 연결은 Suggested path 7(다음 코어 배포 뒤 후속)로 적고 작업 메모에도 남김. 결정 로그 adopted 기록, 구조도 생략 → 기획서 HTML 은 DECK_SKIPPED, 대화 전용 promote 라 readpath update, 대화 frontmatter promoted 로 연결. 다음: /scv:work 20260930-wookiya1364-readme-refresh-core-wrappers.

## Turn 5 — 2026-09-30T10:41:15+09:00
protocol: 24c32f51

**User**: 시작해

**다시 쓴 요청**: 승인된 README 최신화 계획을 실행한다. 검사 스크립트와 붉은 검사를 먼저 만들고, 세 저장소 README 12개를 고치고, 옛 자료 21건을 대조 검토해 검토표를 남긴 뒤 검토를 마친 자료만 다시 사용 표시하고, TESTS 를 돌린다. 보관 · PR · 병합 · main 승격 전에는 결과를 보고하고 확인받는다. (적용한 가이드 규칙: opus-5-5 "Unattended agentic runs — keep the task's parts in a checklist", best-practices "Minimizing hallucinations in agentic coding")

**Claude Code**: /scv:work 실행(effort heavy — 래퍼까지 번지는 변경). 세 저장소에 docs/readme-refresh 브랜치. 옛 자료 21건은 보조 에이전트 셋에 7건씩 읽기 전용으로 맡김 → 검토표 STALE_REVIEW.md(유효 8 · 일부 낡음 12 · 대체됨 1; 검토자 간 기준 차이를 "문제 서술은 역사"로 통일해 1번만 유효로 바뀜). tools/check-readme.sh(명령 · 설정 · 링크 실재, 필수 주제, 세 언어판 일치, 버전 번호 없음, 다른 호스트 문법 없음)와 tests/test-check-readme.sh(붉은 사본 6가지) — 지금 README 에서 먼저 붉음 확인, 기존 불일치 둘 발견(코덱스 플러그인 한 · 일 판의 옛 $scv:sync 안내, 코어 한국어 판에만 있던 문서 링크). README 12개 갱신 — 코어는 버전 표를 파일 링크로 · 설계 절에 매 턴 / 계획 · 증적 · 기록 소절, 클로드 · 코덱스는 업데이트 방법 · 매 턴 기능 · 얻는 것 4행 · 설정 · 가드레일. 코덱스에는 세션 시작 훅과 조사 에이전트가 없어 재개 요약 · 배경 조사를 적지 않음(계획 표 반영). 검사: 세 프로필 OK(맥 bash 3.2 도), 붉은 검사 6/6, 코어 tests/run.sh · run-dry 962/0 · core/tests 실패 0, 클로드 계약 · run-dry 966/0, 코덱스 인용 검사 OK · 코어 트리 검사는 로컬 무시 폴더(node_modules 링크) 탓에 실패했으나 깨끗한 사본에서 통과. 경고 판정이 파일 이름 끝부분으로 맞춰져 오탐이 섞임(11건) — 후속 후보, 그래서 사용함 표시는 보관 커밋 뒤로. 결정 요청: 회귀 건너뛰기 · 보관과 PR · 초록이면 병합과 release=false 승격 · 대화 보관.

## Turn 6 — 2026-09-30T10:41:15+09:00
protocol: 24c32f51

**User**: 전부 추천

**다시 쓴 요청**: 회귀 검사는 건너뛰고 README 최신화 계획을 보관한 뒤, 세 저장소를 커밋해 PR 을 만들고 옛 자료 21건을 "사용함"으로 표시해 경고 해제를 확인한다. CI 가 모두 초록이면 병합하고 릴리스 없이 main 까지 올려 첫 화면을 확인하며, README 대화 기록도 보관한다. CI 가 붉으면 병합하지 않고 멈춰 보고한다. (적용한 가이드 규칙: best-practices "Balancing autonomy and safety")

**Claude Code**: 진행 — 보관(work.sh --archive) · 결정 로그 · 이 대화 보관 → 코어 커밋 · 사용함 표시 커밋 · PR, 두 래퍼 커밋 · PR → CI 초록이면 병합 · promote release=false → main README 확인.
