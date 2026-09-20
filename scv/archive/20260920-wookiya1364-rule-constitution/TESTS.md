# Test Plan — 규칙 헌법 — 최상위 불변식과 해소 순서 한 문장

## Overview

검증할 것은 셋이다. (1) `scv/SCV.md` Top-level rules 절이 7개 이하의 출처 있는 조항과 해소 순서
문단으로 되어 있다. (2) 우선순위를 서술하는 자리가 저장소에 한 곳뿐이고, 옛 3곳은 참조형이다.
(3) 새 검사 스크립트가 원본에서 통과하고 심어 둔 위반에서는 실패한다 — 통과만 하고 아무것도 안
보는 검사는 없느니만 못하다. 그 위에 기존 테스트 전부와 템플릿 동기화 정책이 그대로임을 본다.
T6 은 사람이 읽는 문서 검사다: 대화에서 확인한 충돌 A~E 에 해소 순서를 적용한 결과가 하나로
정해지는지.

## Test scenarios

### T1. 헌법 조항 수와 출처

- **Setup**: `core/template/scv/SCV.md` 의 `## Top-level rules` 절.
- **Run**: 절 안의 번호 항목(`^[0-9]+\. `)을 세고, 각 항목에 `Source:` 가 있는지 본다 (SCV.md 는 영문 템플릿이라
  표기는 영문 — 계획서의 `출처:` 와 같은 뜻).
- **Expected**: 항목 수 3 이상 7 이하. 모든 항목에 `Source:` 가 있다. 절 안에 "Resolution order" 문단이 있다.
- **Pass criterion**: `test-rule-constitution.sh` 의 T1 블록이 `✓` 세 줄을 낸다.

### T2. 해소 순서 서술은 한 곳뿐 (검사 a, 게이트)

- **Setup**: 검사 대상 `core/protocols/**/*.md`, `core/contracts/*.md`, `core/template/**/*.md`,
  `core/template/hooks/*.sh`.
- **Run**: 우선순위 어휘(override / overrides / 우선 / precedence / takes priority / wins /
  supersede 를 제외한 순위 어휘)를 담은 규범 문장을 뽑아, SCV.md Top-level 절 밖의 것은
  참조형("Top-level rules" 를 가리키는 문장)인지 본다.
- **Expected**: 참조형이 아닌 우선순위 문장은 0건.
- **Pass criterion**: 검사 (a) 가 `pass`. 0건이 아니면 파일:줄 목록을 출력하고 실패.

### T3. 국소 우선순위 문장 3곳이 참조로 바뀌었다

- **Setup**: `core/protocols/codegen.md`, `core/contracts/purity.md`.
- **Run**: 원문 "override the others, but never the pipeline rule" 과 "계약이 검사보다 우선한다" 를
  grep 한다. 그 자리에 "Top-level rules" 참조 문장이 있는지 grep 한다.
- **Expected**: 원문 0건, 참조 문장 각 파일 1건 이상.
- **Pass criterion**: 두 grep 결과가 기대와 같다.

### T4. 사용자 지침 양보 조항

- **Setup**: SCV.md Top-level rules 절.
- **Run**: "Yield to the user" 조항과 "one line" 문구가 있는지 본다.
- **Expected**: 조항 하나가 있다.
- **Pass criterion**: grep 1건 이상.

### T5. 중복 요구 래칫 (검사 b)

- **Setup**: 검사 대상은 T2 와 같다. 기준선 `core/tests/fixtures/rule-constitution/duplicate-baseline.txt`.
- **Run**: 규범 문장을 정규화 키로 만들고, 두 파일 이상에 나온 키를 센다. 기준선과 비교한다.
- **Expected**: 후보 수가 기준선 이하. 기준선 파일이 없으면 생성하고 그 사실을 알린다(첫 실행).
- **Pass criterion**: `compare_ratchet` 이 `pass`. 늘었으면 새로 생긴 키와 파일 쌍을 출력하고 실패.

### T6. 충돌 A~E 에 해소 순서 적용 — 결과가 하나로 정해진다 (문서 검사, 사람이 확인)

- **Setup**: PLAN.md Approach 6 의 표. 대화 파일 Turn 2 의 충돌 원문 위치.
- **Run**: 충돌마다 해소 순서 (1)~(4) 를 차례로 대 보고, 처음으로 갈리는 단계와 결과를 적는다.
- **Expected**:
  - A → 이 계획의 T10 이 regression 규칙을 고치고 대체 선언 → (4) → 결정 표 하나 (슬러그별 행).
  - B → (2) → 미완료 대화가 있으면 B0 질문만 하고 멈춘다.
  - C → (3) 액션 단계 규칙 > 상시 문구 → 버전을 적는다.
  - D → 충돌 아님, 빈 규칙 → 순서 적용 대상 아님. (후속 ②가 기록 의무를 공통 계약으로.)
  - E → 범위 불일치 → 런타임 충돌 없음. (후속 ②가 동의 기준을 한 문장으로.)
- **Pass criterion**: 다섯 줄 모두 결과가 하나이고, 리뷰어가 표에 서명한다(ARCHIVED_AT 에 한 줄).

### T10. 충돌 A 해소 — regression 삭감이 결정 표 하나로 묻는다

- **Setup**: `core/protocols/regression.md`.
- **Run**: 원문 "Don't bundle multiple failures into one triage" 와 "For each slug in `failed_slugs`, ask the user one
  independent question" 을 grep 한다. 새 문장(결정 표 하나, 슬러그별 행, 3택과 추천)과 대체 선언("옛 '슬러그마다
  질문 하나' 규칙을 대체한다")을 grep 한다. `--ci` 모드 규칙 줄("must NOT ask interactive questions")을 grep 한다.
- **Expected**: 옛 문장 0건. 새 문장과 대체 선언 각 1건 이상. `--ci` 규칙 줄은 그대로 1건. Step 2 의 [1]~[3]
  동작 설명(regression / obsolete / flaky 의 후처리)은 문장 수가 줄지 않았다.
- **Pass criterion**: 네 grep 결과가 기대와 같다. 문서 검사로 리뷰어가 표 템플릿이 help 의 Decisions 표 형식과
  같은 열(`# | 슬러그 | 실패 꼬리 | 추천`)임을 확인한다.

### T7. 자기 검사 — 심어 둔 위반에서 실패한다

- **Setup**: 픽스처 `core/tests/fixtures/rule-constitution/violation-precedence/` (프로토콜 사본에
  "X overrides Y" 문장을 심음), `.../violation-duplicate/` (같은 규범 문장을 두 파일에 심음).
- **Run**: `test-rule-constitution.sh --self-test`.
- **Expected**: 첫 픽스처에서 검사 (a) 가 실패하고 그 줄을 가리킨다. 둘째 픽스처에서 검사 (b) 의
  후보 수가 기준선보다 1 크다. 멀쩡한 원본에서는 둘 다 통과.
- **Pass criterion**: 세 결과가 기대와 같다.

### T8. 기존 테스트 전부 통과

- **Setup**: 저장소 원본.
- **Run**: `for t in core/tests/test-*.sh; do bash "$t"; done`, `bash core/tests/run-dry.sh`,
  `bash tests/run.sh`.
- **Expected**: 실패 0.
- **Pass criterion**: 모든 종료 코드 0.

### T9. 템플릿 지문과 병합 정책

- **Setup**: `core/TEMPLATE_DIGEST`, `TEMPLATE_VERSION`, PROJECT:LOCAL 블록이 있는 SCV.md 픽스처
  (`core/tests/test-sync-dirty.sh` T6, `run-dry.sh` sync 시나리오 6).
- **Run**: `compute-template-digest.sh --check core/TEMPLATE_DIGEST`. TEMPLATE_VERSION 을 읽는다.
  동기화 테스트를 돌려 픽스처의 PROJECT:LOCAL 블록이 그대로인지 본다.
- **Expected**: 지문 일치. TEMPLATE_VERSION 은 2.3.0 그대로 (릴리스 규칙: 스키마 변경에만 올린다 — 내용
  변경은 지문이 잡는다). 로컬 블록 불변.
- **Pass criterion**: 지문 검사 exit 0 + `test-sync-dirty.sh` 통과. (`test-autosync.sh` 는 CI 에서 돈다 — 그 T9w 는 옆에
  체크아웃된 래퍼 저장소의 문서를 보므로 이 계획의 실행 명령에서는 뺐다.)

## How to run

```bash
bash core/tests/test-rule-constitution.sh && bash core/tests/test-rule-constitution.sh --self-test && bash core/scripts/compute-template-digest.sh --check core/TEMPLATE_DIGEST && bash core/tests/test-sync-dirty.sh && bash core/tests/run-dry.sh && bash tests/run.sh
```

## Pass criteria

- T1~T5, T7~T10 자동 통과. T6 은 리뷰어 확인 한 줄.
- 우선순위 서술 자리가 저장소에 한 곳.
- 조항 7개 이하, 각각 출처 있음.
- `core/TEMPLATE_DIGEST` 재계산, CHANGELOG 항목 존재, TEMPLATE_VERSION 은 그대로.

## Related Documents

- `../../conversations/20260920-112254-jev-laya-concepts-scv.md` — 충돌 원문 위치 (Turn 2).
- `../../../core/contracts/purity.md` — `--self-test` 를 두는 이유.
