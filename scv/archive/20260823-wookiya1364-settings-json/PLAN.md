---
title: "설정을 .env 에서 scv/scv_settings.json 으로 — 읽는 입구를 순수함수 하나로"
slug: 20260823-wookiya1364-settings-json
author: "wookiya1364"
created_at: 2026-08-23
status: done
kind: feature
lang: korean
tags: [settings, config, pure-function, breaking, template, wrappers]
raw_sources: []
refs: []
supersedes: []
scope:
  - "core/scripts/lib/settings.sh"        # 신설 — 순수 조회/해석
  - "core/scripts/lib/env.sh"             # 축소 → 3단계에서 제거
  - "core/scripts/settings-set.sh"        # 신설 (env-set.sh 대체)
  - "core/scripts/settings-migrate.sh"    # 신설 — .env → 두 JSON, 1회
  - "core/scripts/settings-merge.sh"      # 신설 — 새 키만 더한다
  - "core/scripts/env-set.sh"             # 3단계에서 제거
  - "core/scripts/**"                     # 직접 읽던 24군데 교체
  - "core/protocols/*.md"                 # 16개 문서, 약 90줄
  - "core/template/.env.example.scv"      # 3단계에서 제거
  - "core/template/scv/scv_settings.example.json"        # 신설 (예시만; 실제 파일은 사용자 데이터)
  - "core/template/scv/scv_settings.secret.example.json" # 신설
  - "core/template/.gitignore.fragment"   # 비밀 설정 무시 규칙
  - "core/template/hooks/on-user-prompt.sh"
  - "core/template/scv/SCV.md"
  - "core/template/scv/REPORTING.md"
  - "core/tests/**"
  - "docs/wrapper-integration.md"
  - "CHANGELOG.md"
  - "(별도 저장소) scv-claude-code, scv-codex — 스크립트 사본·문서"
invariants:
  - "값을 찾는 순서는 항상 환경변수 → 비밀 설정 → 일반 설정 → 기본값. 바뀌지 않는다"
  - ".env 는 읽지 않는다. 되돌아가기 경로를 두면 이 이사의 목적이 사라진다"
  - "이사가 안 됐으면 조용히 기본값으로 떨어지지 않는다 — 한 액션에 한 번 알린다"
  - "업데이트는 사용자가 정한 값을 절대 바꾸지 않는다. 없는 키만 더한다"
  - "설정 파일은 사용자 데이터다 — 설치가 실제 파일을 만들지 않는다 (예시만)"
  - "조회 함수의 순수부는 파일·시각·네트워크를 건드리지 않는다 — 텍스트와 키만 받고 값만 낸다"
  - "비밀 설정 파일은 어떤 경우에도 커밋되지 않는다 (무시 규칙 + 테스트로 이중 확인)"
  - "일반 설정 파일에 비밀값 키가 들어 있으면 경고하고 무시한다 — 조용히 읽지 않는다"
  - "설정 파일이 없거나 깨져 있어도 스크립트는 죽지 않는다 — 기본값으로 계속 간다"
  - "1단계가 끝난 시점의 동작은 지금과 완전히 같다 — 기존 테스트 전부 통과"
---

# 설정을 scv/scv_settings.json 으로

## Summary

지금 SCV 설정은 프로젝트 루트 `.env` 에 있다. 이게 두 가지 문제를 만든다.

첫째, **오해가 잦다.** `.env` 는 프로젝트가 원래 쓰던 파일이라 SCV 값과 앱 값이
섞인다. 어느 게 SCV 것인지 매번 헷갈린다.

둘째, **읽는 방법이 제각각이다.** 24군데가 각자 파일을 뒤진다. 규칙이 하나가
아니라서 한 곳을 고쳐도 다른 곳이 그대로다.

설정을 `scv/scv_settings.json` 하나로 옮기고, 읽는 입구를 순수함수 하나로 모은다.
비밀값은 `scv/scv_settings.secret.json` 으로 갈라서 커밋되지 않게 한다.

## Goals / Non-Goals

**Goals**

1. 사용자가 손대는 설정 23개를 `scv/scv_settings.json` 에서 읽는다.
2. 비밀값 13개를 `scv/scv_settings.secret.json` 으로 분리하고 무시 목록에 넣는다.
3. 읽는 입구를 **순수 조회 함수 하나**로 모은다 — 24군데의 개별 파싱을 없앤다.
4. `.env` 관련 자산을 전부 제거한다 — 예시 파일, 쓰기 스크립트, 전용 테스트, 문서.
5. 기존 프로젝트를 위한 **1회 이전 절차**를 제공한다.

**Non-Goals**

- **키 이름은 바꾸지 않는다.** 문서 90줄이 지금 이름을 쓴다. 이름 정리는 별건이다.
- **환경변수 자체는 없애지 않는다.** 스크립트끼리 값을 넘기는 데 40개 넘게 쓰고
  테스트도 그 방식으로 돈다. 없애려는 것은 *설정 파일* 이지 환경변수가 아니다.
- 알림·PR·첨부 기능의 동작은 바꾸지 않는다. 값을 어디서 읽는지만 바뀐다.

## 값의 분류 (36개)

`.env.example.scv` 가 안내하던 키 전부를 셋으로 가른다.

### 일반 설정 → `scv/scv_settings.json` (커밋) — 23개

| 묶음 | 키 |
|---|---|
| 프로젝트 | `PROJECT_NAME`, `SCV_DIR` |
| 언어 | `SCV_LANG`, `SCV_PROMOTE_LANG`, `SCV_PLAIN_LANGUAGE`, `SCV_PLAIN_MAX_SENTENCES` |
| 알림 | `NOTIFIER_PROVIDER`, `NOTIFIER_DRY_RUN`, `NOTIFIER_RETRY_MAX` |
| PR | `SCV_PR_PLATFORM`, `GITLAB_HOST` |
| 첨부 | `SCV_ATTACHMENTS_BACKEND`, `SCV_ATTACHMENTS_BRANCH`, `SCV_ATTACHMENTS_RETENTION_DAYS` |
| GIF | `SCV_GIF_FPS`, `SCV_GIF_MAX_SECONDS`, `SCV_GIF_WIDTH` |
| 동작 | `SCV_EFFORT_MODE`, `SCV_FAST_PATH_LINE_THRESHOLD`, `SCV_STATUS_CACHE_TTL` |
| 외부 링크 | `JIRA_BASE_URL`, `LINEAR_BASE_URL`, `CONFLUENCE_BASE_URL` |

### 비밀 설정 → `scv/scv_settings.secret.json` (무시) — 13개

| 묶음 | 키 |
|---|---|
| 토큰 | `SLACK_BOT_TOKEN`, `DISCORD_BOT_TOKEN`, `GITLAB_TOKEN` |
| Slack 채널 | `SLACK_CHANNEL_ID`, `_PHASE_COMPLETE`, `_DAILY_SUMMARY`, `_ERROR_ALERT`, `_E2E_FAILURE` |
| Discord 채널 | `DISCORD_CHANNEL_ID`, `_PHASE_COMPLETE`, `_DAILY_SUMMARY`, `_ERROR_ALERT`, `_E2E_FAILURE` |

채널 ID 는 엄밀히 비밀은 아니지만 조직 내부 식별자다. 토큰과 같은 쪽에 둔다.

### 내부 전달용 → 손대지 않음 — 40개 남짓

`SCV_CORE_ROOT`, `SCV_GUARD_*`, `SCV_HOST_*`, `SCV_LIB_DIR_*`, `SCV_ROOT`,
`SCV_TARGET`, `SCV_DECK_RUNTIME_TEST_*` 등. 이건 사람이 적는 값이 아니라
스크립트가 서로 넘기는 값이다. 설정 파일과 무관하다.

## 설계 — 순수부와 효과부

읽기를 세 조각으로 가른다. 앞의 둘은 순수하다.

```
# 순수 — 설정 텍스트와 키를 받아 값만 낸다
settings_lookup   <json_text> <key>            -> value | (빈 문자열)

# 순수 — 네 후보를 받아 우선순위대로 하나를 고른다
settings_resolve  <env> <secret> <plain> <default>  -> value

# 효과 — 파일 두 개를 읽어 위 둘에 넘긴다. 이 함수만 디스크를 만진다
settings_get      <key> [default]              -> value
```

**우선순위**는 `settings_resolve` 안에 한 번만 적힌다:
**환경변수 → 비밀 설정 → 일반 설정 → 기본값.**
지금은 이 순서가 24군데에 제각각 흩어져 있고, 일부는 순서가 다르다.

순수한 두 함수는 파일도, 시각도, 네트워크도 건드리지 않는다. 그래서 고정 입력에
고정 출력이고, 테스트가 결정적이다. **완료 판정에 사람이나 모델의 판단이 끼지
않는다** — 이 작업이 그 원칙의 첫 사례다.

## 단계

각 단계는 그 자체로 되돌릴 수 있고, 중간에 멈춰도 저장소가 깨지지 않는다.

### 1단계 — 읽는 입구를 모은다 (완료, 동작 변화 없음)

- `lib/settings.sh` 신설. 순수부(우선순위·JSON 조회)와 효과부(파일 읽기)를 가른다.
- 직접 뒤지던 자리를 `settings_get` 으로 돌린다.

**완료 판정**: 기존 테스트 스위트 전부 통과. — **충족.** run-dry 972 PASS/0 FAIL.

**계획서의 숫자가 틀렸다.** "직접 읽는 곳 24군데" 는 과장이었다. 실제로 값을 읽는
자리는 셋이고 나머지는 주석·안내 문구와 검색 오탐이었다. 그리고 `lib/env.sh` 의
`env_load` 가 이미 이음매였다 — 스크립트 열 곳이 그걸 거치므로 2단계에서 그
안쪽만 바꾸면 됐다.

### 2단계 — 저장소를 갈아끼운다 (완료)

- 읽기가 두 JSON 을 본다. **`.env` 는 읽지 않는다** — 되돌아가기 경로를 두면
  "이 값이 어디서 왔지" 가 그대로 남아 이사하는 의미가 없다.
- 다만 조용히 기본값으로 떨어뜨리지도 않는다. `.env` 에 SCV 키가 남아 있으면 한
  액션에 한 번 알리고 옮기는 명령을 준다. SCV 키가 없는 `.env` 는 남의 파일이라
  참견하지 않는다.
- 이전 절차 신설 — 한 번만 돌고, 원본을 지우지 않고, SCV 가 아는 키만 옮긴다.
- **업데이트가 사용자 설정을 바꾸지 않는다.** 없는 키만 더한다. 사용자가 정한
  값도, 일부러 비운 값도, SCV 가 모르는 키도 그대로다. 순수함수이고 sync 가 부른다.

**완료 판정**: 새 파일만으로 모든 값이 읽힌다. 비밀 파일이 무시 목록에 걸린다.
— **충족.**

**기존 테스트가 실제 결함을 하나 잡았다.** 처음에는 템플릿에 빈 설정 파일을
실었는데, 그 파일이 있다는 것만으로 "이사 완료" 로 판정되어 기존 프로젝트가
템플릿을 받는 순간 설정을 잃었다(run-dry 14건 실패). **설정 파일은 사용자
데이터지 템플릿 뼈대가 아니다** — 예시만 싣고 실제 파일은 이사 절차나 사용자가
만든다.

### 3단계 — 잔재를 지운다 (완료)

- `.env.example.scv`, `env-set.sh`, 전용 테스트 두 개 제거.
- `settings-set.sh` 가 `env-set.sh` 를 대신한다. **키가 비밀이면 무시되는 파일로
  자동으로 간다** — 사람이 고르지 않으므로 실수로 토큰을 커밋할 경로가 없다.
- 문서 16개 갱신. 표식(`SCV_PLAIN_LANGUAGE=off` 등)은 계약이라 그대로 두고 파일
  이름만 바꿨다.
- `scv/SCV.md` 에 설정 절 신설 — 두 파일, 이사 명령, 업데이트가 값을 안 바꾼다는 것.

**완료 판정**: 저장소 어디에도 `.env` 를 설정으로 읽는 코드가 없다. — **충족.**
(이사 전용 파서 한 곳만 남고, 그것은 옮길 때만 쓰인다.)

## 위험과 대응

| 위험 | 대응 |
|---|---|
| **비밀값이 커밋된다** | 무시 규칙 + 일반 설정에 비밀 키가 있으면 경고 후 무시 + 그걸 확인하는 테스트 |
| **기존 프로젝트가 깨진다** | 2단계의 1회 이전 절차. 원본은 지우지 않는다 |
| **JSON 파싱 도구가 없다** | `jq` 우선, 없으면 `python3`, 둘 다 없으면 기본값으로 계속 간다 (지금 첨부 기능과 같은 방식) |
| **래퍼 두 곳이 어긋난다** | 3단계를 래퍼 반영까지 포함해 하나로 본다 |
| **JSON 이 깨져 있다** | 죽지 않는다. 경고 한 줄 내고 기본값 사용 |

## 미결 사항

- **래퍼 두 곳 반영.** core 를 벤더링해야 실제 사용자에게 간다. 별도 저장소다.
- **템플릿 버전.** 올리지 않았다. 갱신은 이제 내용 지문으로 판단하므로 번호를
  올리지 않아도 전달된다(20260823-wookiya1364-template-refresh).
- **변경 이력.** 이 저장소는 릴리스 커밋에서 쓰는 방식이라 미뤘다.
- **채널 ID 를 비밀 쪽에 둔다** — 사용자 결정. 팀에서 공유하고 싶으면 나중에 옮긴다.

## 다음 작업과의 연결

이 작업이 끝나면 순수함수 + 파이프 + 결정적 테스트의 실제 사례가 하나 생긴다.
그 형태를 그대로 **저널 색인**에 적용한다. 그 위에 컨텍스트 비우기가 얹힌다.
호스트 조사는 이미 끝났다 — 비운 직후 다시 채워 넣을 자리가 있다는 것까지 확인됐다.
