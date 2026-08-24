---
title: "설정 파일은 항상 있고, 모든 키가 보인다"
slug: 20260824-wookiya1364-settings-always-present
author: "wookiya1364"
created_at: 2026-08-24
status: done
kind: feature
lang: korean
tags: [settings, autosync, hydrate, onboarding]
raw_sources:
  - scv/raw/stale/20260824-wookiya1364-settings-always-present.md
refs: []
supersedes: []
scope:
  - "core/scripts/lib/settings.sh"
  - "core/scripts/lib/scvroot.sh"
  - "core/scripts/settings-ensure.sh"
  - "core/scripts/settings-migrate.sh"
  - "core/scripts/settings-merge.sh"
  - "core/scripts/hydrate.sh"
  - "core/scripts/help.sh"
  - "core/template/scv/scv_settings.example.json"
  - "core/template/scv/scv_settings.secret.example.json"
  - "core/TEMPLATE_DIGEST"
  - "core/tests/**"
  - "CHANGELOG.md"
invariants:
  - "사용자가 이미 정한 값은 절대 바꾸지 않는다 — 있는 파일에는 없는 키만 더한다"
  - "비밀 파일은 git 이 실제로 무시할 때만 만든다(check-ignore 로 확인); 아니면 만들지 않고 한 줄 알린다"
  - "비어 있음이 '자동 감지'를 뜻하는 키(SCV_LANG·SCV_PROMOTE_LANG·NOTIFIER_PROVIDER·SCV_ATTACHMENTS_SLUG·SCV_PR_PLATFORM·PROJECT_NAME·SCV_DIR·*_BASE_URL)는 빈 값으로 만든다 — 동작이 바뀌면 안 된다"
  - ".env 는 절대 수정·삭제하지 않는다"
  - "설정 읽기 순서(환경변수 → 비밀 → 일반 → 기본값)와 순수부/효과부 경계는 그대로"
---

# 설정 파일은 항상 있고, 모든 키가 보인다

## Summary

0.32.0 이 설정을 `scv/scv_settings.json` 으로 옮겼지만, 그 파일을 **만드는 일은
사람 몫**으로 남겨 두었다(수동 이사 스크립트, 또는 예시 파일 복사). 팀 피드백:
(1) 업데이트해도 파일이 안 생기는 경우가 있고, (2) `.env` 에 아무것도 없던 사람은
빈 파일을 받아 무엇을 설정할 수 있는지 알 길이 없다. 두 가지를 한 번에 닫는다 —
액션이 시작될 때 파일이 없으면 **전체 키 + 기본값 + 설명**으로 만들고, `.env` 에
값이 있으면 그 값을 쓴다. 있으면 없는 키만 더한다.

## Goals / Non-Goals

- **Goals**
  1. `settings-ensure.sh`(+ lib `settings_ensure`): 공개 설정 파일이 없으면 만든다 —
     공개 키 전부, 기본값(자동 감지 키는 빈 값), `.env` 에 있는 값 우선, 맨 위에
     `_comment` 와 키별 `_doc`(한 줄 설명 + 허용값). 있으면 없는 키만 더한다
     (`_` 로 시작하는 설명 키는 사용자가 지웠으면 다시 넣지 않는다).
  2. 비밀 파일: 없으면 **git 이 무시할 때만** 만든다 — `.gitignore` 에 무시 줄이
     없으면 hydrate 가 하듯 한 줄 더하고 `git check-ignore` 로 확인; 확인되면 비밀
     키 전부 빈 값(+ `.env` 값)으로 생성(600). 안 되면 만들지 않고 한 줄 알림.
  3. 호출 지점: 액션 시작(autosync 직후, `scv_init_paths`)과 hydrate(새 프로젝트는
     예시 파일이 아니라 **실제 파일**을 받는다). `settings-migrate.sh` 는 ensure 의
     별칭이 된다(.env 없어도 파일을 만든다; 두 번 돌려도 같다).
  4. `.env` 잔존 알림: 값이 이미 옮겨져 같으면 조용하다. `.env` 값이 설정 파일과
     **다를 때만** 한 액션에 한 번 알린다(사람이 나중에 .env 를 고친 경우).
  5. 템플릿 예시 JSON 을 "기본값 + 설명" 의 단일 출처로 채운다(merge 도 이 파일을
     읽는다). 진단(help)은 파일이 있음을 전제로 문구를 정리한다.
  6. 회귀 가드: test-settings.sh 에 생성·병합·비밀 무시 조건·자동 감지 키 빈 값·
     알림 침묵/발화·멱등 시나리오.

- **Non-Goals**
  - 설정 키 추가/의미 변경, 읽기 우선순위 변경, `.env` 편집·삭제
  - 래퍼 변경(계약 불변 → 자동 벤더링)

## Approach Overview

**단일 출처.** `core/template/scv/scv_settings.example.json` 이 공개 키의 기본값과
`_doc` 을 함께 담는다. 기본값은 코드가 실제로 쓰는 값(예: 첨부 범위 slug, 재시도 3,
효과 모드 auto, GIF 10/60/480, 보관 3일, 캐시 300초, 줄 임계 5, 문장 상한 2,
쉬운 말 on, GitLab 호스트 기본 주소). 자동 감지 키는 빈 값 + `_doc` 에 "비우면
자동 감지" 명시. 비밀 예시 파일도 전체 비밀 키를 빈 값으로 담는다.

**ensure.** 순수부(`settings_merge_defaults`)는 그대로 쓰고, 효과부 한 함수가
읽기→합치기→쓰기를 한다. 생성 시 `.env` 값은 `_settings_from_env_file` 로만 꺼낸다
(source 금지). 쓰기는 임시 파일 후 이동(원자적), 심볼릭 링크면 거부. 출력은 한 줄:
`scv: settings file created — N keys (M from .env)` / `... added K key(s)` / 침묵.

**비밀 파일 무시 보장.** git 작업 트리이고 `.gitignore` 에 `scv/scv_settings.secret.json`
줄이 없으면 `# --- appended by scv settings-ensure ---` 아래 한 줄을 더한 뒤
`git check-ignore -q` 로 확인. git 이 아니거나 확인 실패면 비밀 파일은 만들지 않는다.

**알림.** `_settings_warn_unmigrated` 는 "설정 파일이 없을 때" 가 아니라 ".env 의 SCV
값이 설정 파일 값과 다를 때" 한 번 찍는다. 문구는 "값이 다르다 — 설정 파일이
진짜다; .env 줄은 지워도 된다" 로 바꾼다.

## Guardrails

- 사용자 값 불변(있는 키는 절대 덮지 않음). `_` 키는 사용자가 지웠으면 재추가 금지.
- 비밀 파일은 무시 확인 없이는 절대 쓰지 않는다. `.gitignore` 에는 한 줄만, 이미
  있으면 안 더한다. `.env` 는 읽기만.
- 자동 감지 키는 빈 값 — 채우면 언어 자동 감지 등이 깨진다(불변 조건).
- 순수부/효과부 경계 유지(`check-purity.sh` 통과), git 상태 단언 금지, 호스트 이름 금지.
- 액션 시작 비용: 파일이 있고 키가 다 있으면 읽기 한 번, 출력 없음.

## Exit criteria

- TESTS How-to-run exit 0 (test-settings 확장 포함, 스위트 전량).
- 실측 2건(배포 후): (a) 파일 없는 기존 프로젝트에서 아무 액션 → 파일이 전체 키+설명으로
  생김, `.env` 값 반영; (b) 파일 있는 프로젝트 → 사용자 값 그대로, 새 키만 추가.
- CHANGELOG + 0.34.0 릴리스 → 래퍼 두 곳 핀·릴리스.

## Suggested path

1. 템플릿 예시 JSON(기본값 + `_doc`) · 비밀 예시 JSON(전체 키).
2. lib `settings_ensure`(생성/병합/비밀/무시 보장) + `settings-ensure.sh` + migrate 별칭 + 알림 조건.
3. 호출 지점: scvroot(autosync 직후) · hydrate.
4. help 진단 문구, CHANGELOG, 테스트(T14~T16) → 스위트 → archive → PR → 0.34.0.

## Related Documents

- 원재료: `scv/raw/stale/20260824-wookiya1364-settings-always-present.md`
- 선행: `scv/archive/20260823-wookiya1364-settings-json/PLAN.md`

## Risks / Open Questions

- 액션마다 ensure 가 도는 비용 — 파일 존재+키 완비면 JSON 한 번 읽기. 큰 부담 아님.
- `.gitignore` 자동 추가는 루트 파일 수정이다 — hydrate 가 이미 하는 일이고 한 줄뿐이며
  비밀 유출을 막는 쪽이므로 감수한다. 비-git 프로젝트는 비밀 파일을 만들지 않는다.
- 기본값을 파일에 적으면 코드 기본값이 바뀔 때 두 곳이 어긋날 수 있다 — merge 는 값을
  안 바꾸므로 사용자 파일은 옛 기본값을 유지한다(사용자 값으로 취급). CHANGELOG 에 명시.

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
