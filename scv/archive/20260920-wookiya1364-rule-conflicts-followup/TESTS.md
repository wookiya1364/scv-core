# Test Plan — 규칙 충돌 후속 — B~E 해소, 허용목록 두 줄 참조화, pr-helper 재실행 누출

## Overview

문서 변경(B·C·D·E·허용목록)은 두 가지로 고정한다 — 새 문장이 존재하고 옛 문장이 없다는 grep, 그리고 규칙 헌법 검사
(a)(b) 가 여전히 통과한다는 것. 코드 변경(누출 공통화)은 실행기와 pr-helper 양쪽에서 설정값이 자식에 닿지 않음을
픽스처로 고정한다. 마지막으로 B~E 에 해소 순서를 대 본 결과 표를 사람이 확인한다.

## Test scenarios

### T1. 허용목록 두 줄이 참조형이 됐다

- **Setup**: `core/protocols/work.md`, `core/tests/fixtures/rule-constitution/precedence-allowlist.txt`.
- **Run**: 옛 문장 "A plan's Guardrails override them" 과 "overrides the judgment" grep. 허용목록에서 work.md 줄 수.
- **Expected**: 옛 문장 0건. work.md 두 자리에 "Top-level rules" 참조. 허용목록에서 그 두 줄과 "후속이 참조로 바꿀" 주석이 사라짐 — 명사 override 로 남는 한 줄("explicit user override")은 규칙 우선 관계가 아니라 그대로.
- **Pass criterion**: grep 결과 일치 + `test-rule-constitution.sh` (a) 통과.

### T2. B — B0 예외 문장

- **Setup**: `core/protocols/help/full.md` Step B0.
- **Run**: "주제가 명백히 다르면" 또는 영문 동의어("clearly unrelated") 와 "한 줄로 알린다/say so in one line" grep.
- **Expected**: 예외 문장 1개. 기존 세 선택지 문장은 그대로.
- **Pass criterion**: grep 1건 이상, 기존 문장 존재.

### T3. C — 상시 문구에 해소 순서 참조 + 래퍼 핸드오프

- **Setup**: `core/template/hooks/on-user-prompt.sh` PLAIN 블록. 두 래퍼 저장소.
- **Run**: 훅 출력에 "Top-level rules" 참조 문장이 있는지(`bash on-user-prompt.sh` 를 임시 프로젝트에서 실행). 이슈 URL 두 개가 ARCHIVED_AT 에 기록됐는지(보관 시).
- **Expected**: 문장 1개, 우선순위 어휘는 참조형. 이슈 2개.
- **Pass criterion**: grep + 검사 (a) 통과 + URL 2개(사용자 승인 뒤 생성).

### T4. D — 기록 계약 한 곳 + 포인터 7개

- **Setup**: `core/contracts/recording.md`, 프로토콜 12개.
- **Run**: 계약 문서 존재와 다섯 요소(누가·어디·형식·리댁션·짧은 턴) 항목 grep. 모든 Core 프로토콜(13개 — 7개 신설 대상 + 기존 5개 + regression)에 `## Recording` 절과 `contracts/recording.md` 참조 1개씩.
- **Expected**: 13/13 참조 (구현 중 regression 도 삭감 대화가 있어 포함). 기록 절차 본문(Turn 블록 형식 설명)은 계약 문서에만 — 다른 곳의 새 복제 없음.
- **Pass criterion**: grep 12건, `test-rule-constitution.sh` (b) 기준선 이하.

### T5. E — sync 동의 기준 한 문장

- **Setup**: `core/protocols/sync.md`.
- **Run**: "삭제가 없는 갱신은 자동" 류의 동의 기준 문장 grep; 자동 갱신 절과 Step 0 이 그 문장을 가리키는지.
- **Expected**: 기준 문장 1개, 참조 2개.
- **Pass criterion**: grep 일치.

### T6. 누출 공통화 — 실행기와 pr-helper 가 같은 함수

- **Setup**: `core/scripts/lib/env.sh`, `regression.sh`, `pr-helper.sh`.
- **Run**: `env_settings_unset_args` 정의 1곳(env.sh), 호출 2곳. regression.sh 에 옛 `settings_unset_args()` 정의 없음.
- **Expected**: 정의 1, 호출 2, 옛 정의 0.
- **Pass criterion**: grep 일치 + `check-purity.sh` 통과(순수 표식).

### T7. pr-helper 재실행이 설정값을 흘리지 않는다

- **Setup**: `test-regression-env.sh` 새 항목 T8: 설정 파일(SCV_LANG=japanese)이 있는 임시 프로젝트, 보관 슬러그의 `## How to run` 이 `env > 파일` 인 계약, test-results 비움.
- **Run**: `pr-helper.sh <slug> --no-push --no-create`.
- **Expected**: 재실행이 일어나고, 덤프된 자식 env 에 `SCV_LANG` 없음. 실행 전 사용자가 export 한 `SCV_LANG=canary` 는 있음.
- **Pass criterion**: 두 단언 통과.

### T8. B~E 에 해소 순서를 대 본 결과 (문서 검사, 사람이 확인)

- **Run**: 규칙 헌법 해소 순서 (1)~(4) 를 B~E 새 문장에 적용.
- **Expected**: B → 예외 문장(더 좁은 범위) 하나로 정해짐. C → (3) 단계 규칙 우선, 상시 문구가 스스로 그렇게 말함. D → 계약 한 곳, 충돌 없음. E → 기준 한 문장, 두 절이 참조 — 충돌 없음.
- **Pass criterion**: 네 줄 모두 결과 하나. 리뷰어 서명 한 줄(ARCHIVED_AT).

### T9. 전체 검사·지문·맥·리눅스

- **Run**: `test-rule-constitution.sh`(+ `--self-test`), `test-regression-env.sh`, `compute-template-digest.sh --check`, core 테스트 루프, run-dry, tests/run.sh. PR CI 우분투·맥.
- **Expected**: 실패 0.
- **Pass criterion**: 종료 코드 0, CI 초록.

## How to run

```bash
bash core/tests/test-rule-constitution.sh && bash core/tests/test-rule-constitution.sh --self-test && bash core/tests/test-regression-env.sh && bash core/scripts/compute-template-digest.sh --check core/TEMPLATE_DIGEST && bash core/tests/run-dry.sh && bash tests/run.sh
```

## Pass criteria

- T1~T7, T9 자동 통과. T8 리뷰어 확인.
- 허용목록의 "후속" 줄 0개. 기준선 변화는 리뷰된 감소만.
- 래퍼 이슈 2개 URL 기록.
