# 회귀 계약 보수 — 영원히 빨간 아카이브 4건의 정리 기록

2026-08-18. 대표님 결정: "보수 슬러그로 supersede". 누적 회귀에서 구조적으로
성립 불가한 아카이브 테스트 4건을 새 슬러그 하나가 대체한다.

## 확인 — 네 건이 빨간 이유는 기능이 아니라 문서다

`origin/develop` 에서도 동일 재현. 두 부류다.

**부류 1 — 커밋 전 상태 단언 (3건).** `git diff --name-only HEAD -- <경로>` 로
"이번 편집이 이 파일만 건드렸다"를 단언한다. 구현 중 작업 트리에서만 참이고,
커밋된 순간부터 diff 는 빈 값이라 `= "core/protocols/work.md"` 류 등식이 영원히
거짓이다.

- 20260807-wookiya1364-decision-log-activation (TESTS.md:81-82)
- 20260811-wookiya1364-implementation-principles (TESTS.md:65)
- 20260812-wookiya1364-plain-language (TESTS.md:74)

**부류 2 — 존재한 적 없는 파일 호출 (1건).**
20260812-wookiya1364-ci-provenance-gate 의 How-to-run 이
`core/tests/test-provenance.sh` 를 부르는데 git 이력에 그 파일의 추가 기록이
없다. 아카이브된 날부터 끊어져 있었다. 그 기능의 실제 검증은 0.27.0 이 만든
`core/tests/test-provenance-gates.sh` (18케이스) 가 이미 하고 있다.

**네 기능 전부 살아 있다** — 결정 로그, 구현 원칙, 쉬운 말 절, provenance
게이트. 죽은 것은 테스트 문서 쪽이다. 그래서 그냥 obsolete 마킹(선택지 2)은
어긋난다: obsolete 는 "더 이상 유지하지 않는 기능"을 뜻하고, 후속 없이 마킹하면
살아 있는 기능 4개의 회귀 검증이 사라진다.

## 결정 — 보수 슬러그 하나가 넷을 supersede

새 계획 `regression-contract-repair` 의 TESTS.md 가 네 기능의 **내구성 있는
재표현**을 담는다:

- T1 (provenance 게이트): `bash core/tests/test-provenance-gates.sh` — 실존
  스위트 호출로 교체
- T2 (결정 로그): DECISIONS.md 존재·엔트리 수·`path delta:` 필드·status.sh
  노출·guidance-filter lint/full/minimal 생존 — 원본에서 git-diff 단언과
  전체 스위트 재실행만 뺀 것
- T3 (구현 원칙): work.md/codegen.md 원칙 존재·minimal 투영 생존 6구절·호출
  시퀀스 full==minimal — 같은 방식
- T4 (쉬운 말): 대상 프로토콜 전부에 절 존재·문구 상호 동일·마커 규율·minimal
  생존 — 같은 방식

빼는 것 둘의 근거:
- git-diff 범위 단언: 커밋 후 성립 불가가 이번 사태의 원인 그 자체
- 슬러그 내부의 전체 스위트 재실행: 회귀가 슬러그마다 전체 스위트를 또 돌리면
  O(n²) — 이번 실측에서 12슬러그가 10분을 넘긴 주범. 전체 스위트는 CI 와
  릴리스 체크리스트가 이미 돌린다

frontmatter `supersedes:` 에 네 슬러그를 선언하고, 아카이브 시 기존 Step 9c
절차가 넷을 `status: obsolete + obsoleted_at + obsoleted_by` 로 마킹한다 —
frontmatter 3필드는 허용된 경로다. 이후 회귀는 새 계약을 돌리고 넷을 건너뛴다.

## 재발 방지 — 같은 병을 다시 못 쓰게

1. **PROMOTE.md 의 TESTS 작성 규칙에 한 줄**: How-to-run 은 아카이브된 뒤에도
   참이어야 한다 — 커밋 전 상태 단언(`git diff` 범위 검사) 금지, PR 이 싣지
   않는 파일 참조 금지.
2. **tests-smell.sh 에 warn 규칙 추가** (경고 전용, 기존 헌장 그대로):
   How-to-run 블록에 `git diff --name-only HEAD` 가 보이면 "아카이브 후 성립
   불가" 냄새로 플래그. 존재하지 않는 스크립트 경로 참조도 같은 급으로.

## 예상 함정

- 보수 슬러그의 TESTS 는 그 자체가 회귀에서 반복 실행된다 — 위 내구성 규칙을
  스스로 지켜야 한다 (git-diff 단언 없음, 실존 파일만, 전체 스위트 재실행 없음)
- obsolete 마킹은 아카이브 PLAN.md frontmatter 만 — TESTS.md·ARCHIVED_AT.md 는
  바이트 그대로
- PROMOTE.md·tests-smell.sh 변경은 배포 payload — 다음 릴리스(0.29.0)에 실려
  나간다. 보수 슬러그 자체는 저장소 로컬이라 릴리스가 필요 없다
- `test-guard-consistency.sh` 의 구문 스윕: PROMOTE.md 에 넣는 문장이 "by hand"
  류 표현을 쓰지 않게 주의
