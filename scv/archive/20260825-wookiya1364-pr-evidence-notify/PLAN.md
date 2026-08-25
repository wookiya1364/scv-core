---
title: "PR 을 만들면 증적이 Slack 에도 간다 — 성공이어도"
slug: 20260825-wookiya1364-pr-evidence-notify
author: "wookiya1364"
created_at: 2026-08-25
status: done
kind: feature
lang: korean
tags: [pr-helper, notifier, evidence, slack]
raw_sources:
  - scv/raw/stale/20260825-wookiya1364-pr-evidence-notify.md
refs: []
supersedes: []
scope:
  - "core/scripts/pr-helper.sh"
  - "core/scripts/lib/settings.sh"
  - "core/template/scv/scv_settings.example.json"
  - "core/TEMPLATE_DIGEST"
  - "core/protocols/work.md"
  - "core/tests/test-pr-notify.sh"
  - "CHANGELOG.md"
invariants:
  - "알림은 최선 노력 — 어떤 실패도 PR 생성/갱신을 막지 않는다 (경고 한 줄, exit 0)"
  - "알림 채널이 설정 안 된 프로젝트는 아무 일도 없다 — 조용히 건너뛴다"
  - "off 만 끈다 (SCV_PR_NOTIFY, 기본 on — 쉬운말·항상 끼어들기와 같은 규칙)"
  - "게시하는 증적은 PR 에 붙인 것과 동일 목록 — 실행 기록 1순위 규칙을 그대로 따른다"
---

## Why

CI 는 실패만 증적(정책), pr-helper 는 PR 본문에만 첨부 — Slack 에 성공 slug
증적을 올리는 주체가 없었다 (raw 참조). 사용자는 "성공했어도 올라가야 한다".

## What

### 1. 새 설정 키 — `SCV_PR_NOTIFY` (on/off, 기본 on)

`SCV_PLAIN_KEYS` 등록 (27 → 28), 예시 파일 `_doc` + 기본값 `"on"`.
효과는 `NOTIFIER_PROVIDER` 가 설정된 프로젝트에서만 — 미설정이면 무동작.

### 2. pr-helper — PR 성공 후 알림 게시

`PR created:` / `PR updated:` 직후 (dry-run 제외):

- 조건: `SCV_PR_NOTIFY` != off AND `NOTIFIER_PROVIDER` 설정.
- 어댑터 로드(notifiers/<provider>.sh) → `notifier_validate_env` →
  `notifier_resolve_channel phase-complete` → `notifier_post_message`
  (제목: PR 증적 — <slug>; 본문: PR URL · 제목 · 상태) → 반환된 thread_ref 에
  `notifier_upload_file` 로 증적 업로드.
- 증적 목록: 이미 계산된 SCREENSHOTS + VIDEOS 배열 (실행 기록 1순위 —
  0.35.0 계약 그대로). GIF 는 PR 미리보기용이므로 업로드하지 않는다.
- 진행 로그(stderr): `pr-notify: posting …` / `pr-notify: upload <파일>` /
  `pr-notify: done (N file(s))`. 실패 시 `pr-notify: … — continuing` 경고만.
- `NOTIFIER_DRY_RUN=1` 존중 (어댑터가 페이로드를 stderr 로 찍는다).

### 3. 프로토콜 — work.md Step 9d

첨부 문단에 한 줄: 알림 채널이 설정돼 있으면 같은 증적이 Slack/Discord 에도
게시된다 (SCV_PR_NOTIFY=off 로 끔).

## Non-Goals

- 프로젝트 봇이 만든 기존 PR 스레드에 정밀 부착 (스레드 번호는 그 봇만 안다
  — 프로젝트 워크플로 몫, 사용자 합의).
- report 액션 변경 — 기존 phase 보고 경로는 그대로.
- 새 이벤트 종류 추가 — phase-complete 채널 재사용.

## Suggested path

1. test-pr-notify.sh Red → 설정 키 등록 + 예시 파일
2. pr-helper 알림 블록 (+ work.md 문안)
3. Green → 인접 계약(run-manifest·attachments-scope) → 회귀 → archive → PR → 0.36.0 래퍼

## Guardrails

- 기존 계약 불변: pr-helper 의 PR 생성/갱신·첨부·재실행 동작, report 의 알림
  경로, dry-run 출력 형식.
- 호스트 중립, whitespace(파일 끝 빈 줄 금지), 순수성 계약.
- 비밀(토큰)은 로그에 절대 찍지 않는다.

## Exit criteria

- provider 설정 + dry-run: PR 생성 후 `pr-notify:` 로그와 DRY_RUN 페이로드에
  PR URL·증적 파일명이 보인다.
- `SCV_PR_NOTIFY=off` → 알림 없음. provider 미설정 → 조용히 건너뜀.
  검증 실패(토큰 없음) → 경고 한 줄, PR 은 정상 생성 (exit 0).
- `bash core/tests/test-pr-notify.sh` green + `test-run-manifest.sh` ·
  `test-attachments-scope.sh` green.
