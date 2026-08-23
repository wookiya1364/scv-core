# Test Plan — 설정을 scv/scv_settings.json 으로

## Overview

확인하는 것: 순수 조회 함수가 고정 입력에 고정 출력을 내고, 우선순위가 한 곳에만
적혀 있으며, 비밀값이 커밋되지 않고, 설정 파일이 없거나 깨져도 죽지 않고, 1단계
시점의 동작이 지금과 완전히 같다는 것.

**모든 판정은 실행 결과로 내린다.** 사람이나 모델이 "잘 된 것 같다" 고 말하는
자리는 없다. 각 시나리오는 정해진 문자열을 찍거나 못 찍거나 둘 중 하나다.

시나리오는 단계별로 묶인다. 1단계 완료 시 T1–T4, 2단계 완료 시 T5–T9,
3단계 완료 시 T10–T12 가 통과해야 한다.

## Test scenarios

### T1. 순수 조회 — 고정 입력, 고정 출력  ✅

- **Setup**: 파일 없음. 함수에 JSON 문자열을 직접 넘긴다.
- **Expected**:
  - `{"SCV_LANG":"korean"}` + `SCV_LANG` → `korean`
  - 같은 입력을 100회 반복 → 100회 모두 같은 출력
  - 없는 키 → 빈 문자열, exit 0
  - 값이 빈 문자열인 키 → 빈 문자열, exit 0 (없는 것과 구분은 exit code 아님)
  - 값에 공백·따옴표·줄바꿈·유니코드 포함 → 원문 그대로
  - `{"a":{"b":1}}` 같은 중첩 → 최상위 키만 본다, 중첩은 빈 문자열
- **Pass criterion**: `OK [T1]`

### T2. 순수 조회 — 부수효과 없음 (정적 검사)  ✅

- **Setup**: `settings_lookup` 과 `settings_resolve` 의 본문만 추출한다.
- **Expected**: 다음이 **하나도 나오지 않는다** — 파일 읽기/쓰기(`cat`, `>`, `>>`,
  `source`, `read <`), 시각(`date`), 무작위(`$RANDOM`), 네트워크(`curl`, `git`),
  전역 변수 대입(`local` 없는 대입).
- **왜 정적 검사인가**: 이 검사 자체가 순수함수다 — 코드 텍스트를 받아 위반 목록을
  낸다. 원칙이 문서에만 남지 않게 하는 장치다.
- **Pass criterion**: `OK [T2]`

### T3. 우선순위 해석 — 16가지 조합 전수  ✅ `OK [T3] 16/16`

- **Setup**: 네 후보(환경변수 / 비밀 / 일반 / 기본값)의 있음·없음 조합 16가지를
  `settings_resolve` 에 직접 넘긴다.
- **Expected**: 항상 **환경변수 → 비밀 → 일반 → 기본값** 순으로 첫 번째 있는 값.
  넷 다 없으면 빈 문자열. 16행 기대표와 정확히 일치.
- **Pass criterion**: `OK [T3]`

### T4. 1단계 — 동작 무변화 (회귀)  ✅

- **Setup**: 1단계 커밋 상태. `.env` 는 그대로 둔다.
- **Expected**: `core/tests/run.sh` 와 `core/tests/run-dry.sh` 가 **하나도 안 바뀐 채로**
  전부 exit 0. 즉 읽는 입구만 바뀌고 결과는 같다.
- **Pass criterion**: `ALL GATES OK [T4]`

### T5. 2단계 — 새 파일에서 읽는다  ✅

- **Setup**: `.env` 없음. `scv/scv_settings.json` 에 일반 설정 23개,
  `scv/scv_settings.secret.json` 에 비밀 13개.
- **Expected**: 36개 키 전부가 원래 값으로 읽힌다. 하나도 빠지지 않는다.
- **Pass criterion**: `OK [T5] 36/36`

### T6. 비밀 설정은 커밋되지 않는다  ✅

- **Setup**: 새로 만든 프로젝트에 비밀 설정 파일을 쓴다.
- **Expected**:
  - `git check-ignore scv/scv_settings.secret.json` 이 성공(무시됨)
  - `git status --porcelain` 에 그 파일이 **나오지 않는다**
  - `git add -A` 후에도 `git diff --cached --name-only` 에 없다
- **Pass criterion**: `OK [T6]`

### T7. 일반 설정에 비밀 키가 있으면 경고하고 무시  ✅

- **Setup**: `scv/scv_settings.json` 에 토큰 키를 일부러 넣는다.
- **Expected**: 그 값을 **읽지 않는다**(빈 문자열 또는 기본값). 표준오류에 경고 한 줄.
  경고 문구에 값 자체는 절대 찍히지 않는다. exit 0.
- **Pass criterion**: `OK [T7]`

### T8. 없거나 깨져도 죽지 않는다  ✅

- **Setup**: 다음 다섯 가지 —
  파일 없음 / 빈 파일 / 깨진 JSON / 배열(`[]`) / 최상위가 문자열(`"x"`)
- **Expected**: 다섯 경우 모두 exit 0, 기본값 반환, 경고는 표준오류로만.
  호출한 스크립트가 중단되지 않는다.
- **Pass criterion**: `OK [T8] 5/5`

### T9. 이전 절차 — 1회 변환  ✅

- **Setup**: 36개 키가 든 `.env` 가 있고 새 설정 파일은 없다.
- **Expected**:
  - 일반 23개가 `scv_settings.json` 으로, 비밀 13개가 `scv_settings.secret.json` 으로
  - 원본 `.env` 는 **지워지지 않는다** (내용도 그대로)
  - SCV 와 무관한 키(예: 앱이 쓰던 값)는 어느 쪽에도 옮겨지지 않는다
  - 새 설정 파일이 이미 있으면 아무것도 하지 않고 그렇게 말한다
  - 두 번 실행해도 결과가 같다
- **Pass criterion**: `OK [T9]`

### T10. 3단계 — .env 를 설정으로 읽는 코드가 없다  ✅

- **Setup**: 3단계 커밋 상태의 저장소 전체.
- **Expected**: `core/` 아래에서 설정 목적의 `.env` 읽기가 0건.
  (이전 절차 스크립트 안의 읽기 1곳은 허용 목록으로 명시 — 그 외 0건)
  `core/template/.env.example.scv`, `core/scripts/env-set.sh`,
  `core/scripts/lib/env.sh` 가 존재하지 않는다.
- **Pass criterion**: `OK [T10]`

### T11. 값 쓰기 — 무관한 줄은 그대로  ✅

- **Setup**: 설정 파일에 키 여러 개와 사용자가 넣은 주석/순서가 있다.
- **Expected**: 키 하나를 바꿔도 다른 키의 값이 바뀌지 않는다. 파일이 유효한 JSON 을
  유지한다. 파일이 없으면 만든다. 비밀 키를 일반 파일에 쓰려 하면 거부한다.
- **Pass criterion**: `OK [T11]`

### T12. 래퍼 두 곳 반영  ⏳ **미완**

- **Setup**: 두 래퍼 저장소에 이번 core 를 벤더링한 상태.
- **Expected**: 두 곳 모두 `.env.example.scv` 사본이 없고, 문서에 `.env` 설정 안내가
  없으며, 각자의 테스트가 exit 0.
- **Pass criterion**: `OK [T12]` (래퍼별로 각각)

## How to run

```bash
# 단계별
bash core/tests/test-settings-pure.sh      # T1 T2 T3
bash core/tests/run.sh && bash core/tests/run-dry.sh   # T4
bash core/tests/test-settings-file.sh      # T5 T6 T7 T8 T9 T11
bash core/tests/test-settings-cleanup.sh   # T10
# T12 는 각 래퍼 저장소에서
```

## 이 테스트 계획이 지키는 것

- **판정이 문자열 비교다.** `OK [Tn]` 이 나오거나 안 나오거나다.
- **T1 은 반복 가능성 자체를 검사한다.** 같은 입력에 다른 출력이 나오면 실패다.
- **T2 는 원칙을 기계로 강제한다.** 순수해야 할 자리에 효과가 섞이면 거기서 멈춘다.
- **T3 은 전수다.** 우선순위는 16가지가 전부라 표본이 아니라 전체를 본다.
- **T4 는 1단계가 아무것도 안 바꿨음을 증명한다.** 이게 통과해야 2단계가 안전하다.

## 계약이 바뀐 곳 (계획 수립 이후)

- **`.env` 되돌아가기 없음.** 계획서는 2단계에 되돌아가기를 뒀지만, 사용자 결정으로
  없앴다. 읽는 곳은 두 JSON 뿐이다. 대신 이사가 안 됐으면 **한 액션에 한 번**
  알린다 — 조용한 실패는 안 된다. SCV 키가 없는 `.env` 는 남의 파일이라 참견하지
  않는다.
- **T13 신설 — 업데이트가 사용자 설정을 바꾸지 않는다.** 없는 키만 더한다. 사용자가
  정한 값도, 일부러 비운 값도, SCV 가 모르는 키도 그대로다. 깨진 입력에서는 사용자
  원본을 그대로 낸다 — 병합하다 설정을 잃느니 아무것도 안 하는 편이 낫다.
- **설치가 실제 설정 파일을 만들지 않는다.** 만들면 그 존재만으로 "이사 완료" 로
  판정되어 기존 프로젝트가 설정을 잃는다. 예시 파일만 싣는다.

## 현재 상태 (2026-08-23)

| 항목 | 결과 |
|---|---|
| T1 T2 T3 T5 T6 T7 T8 T9 T13 | `test-settings.sh` 58건 통과 |
| T4 회귀 | run-dry 973 PASS / 0 FAIL |
| T10 | 설정 목적의 `.env` 읽기 0건 (이사 전용 파서만 남음) |
| T11 | `settings-set.sh` — 비밀 키는 무시되는 파일로 자동 분기, 값은 화면에 안 찍음 |
| T12 | 미완 — 래퍼 벤더링 필요 |
