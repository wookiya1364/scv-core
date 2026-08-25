---
title: "증적 영상은 사람 속도로 — 전환당 2초, 짧으면 경고"
slug: 20260825-wookiya1364-evidence-pacing
author: "wookiya1364"
created_at: 2026-08-25
status: done
kind: feature
lang: korean
tags: [evidence, video, pacing, pr-helper]
raw_sources:
  - scv/raw/stale/20260825-wookiya1364-evidence-pacing.md
refs: []
supersedes: []
scope:
  - "core/scripts/lib/evidence.sh"
  - "core/scripts/pr-helper.sh"
  - "core/scripts/lib/settings.sh"
  - "core/template/scv/scv_settings.example.json"
  - "core/TEMPLATE_DIGEST"
  - "core/protocols/work.md"
  - "core/protocols/codegen.md"
  - "core/tests/test-evidence-pacing.sh"
  - "CHANGELOG.md"
invariants:
  - "검사는 경고만 한다 — 영상이 짧아도 PR·첨부·알림은 그대로 진행"
  - "ffprobe 가 없으면 조용히 건너뛴다 — 새 필수 의존성을 만들지 않는다"
  - "스펙의 유지 시간은 스펙의 일부다 — Green 을 빠르게 하려고 걷어내지 않는다"
  - "임계는 설정 키 하나 (SCV_EVIDENCE_MIN_SECONDS, 기본 4) — 등록부·예시에 함께 실린다"
---

## Why

slug 증적 영상이 사람 인지 속도(전환당 ~2초)보다 빨리 지나간다 (raw 참조).
스펙이 기계 속도로 달리는 것이 원인 — 규칙과 기계 검사가 둘 다 필요하다.

## What

### 1. 스펙 작성 규칙 — work.md Step 5b · codegen.md

- work.md Step 5b 에 문단: 의미 있는 화면 전환 뒤 ≥2초 유지
  (예: `await page.waitForTimeout(2000)`), 전환 N번 → 영상 ≥2N초.
- codegen.md 스펙 규칙에 한 줄: 유지 시간은 스펙의 일부 — Green 을 빠르게
  하려고 제거 금지.

### 2. 기계 검사 — `lib/evidence.sh` + pr-helper

- `evidence_min_seconds`: `SCV_EVIDENCE_MIN_SECONDS`(양의 정수, 기본 4).
- `evidence_video_seconds <file>`: ffprobe 로 초 단위 길이(정수). ffprobe
  없음/실패 → 빈 값, exit 0.
- `evidence_warn_short <file>`: 길이 < 임계 → stderr 한 줄 경고
  (`evidence: <파일> is <X>s — shorter than <N>s …`), 항상 exit 0.
- pr-helper: 첨부 목록 확정 직후 VIDEOS 각각에 `evidence_warn_short`.

### 3. 설정 키 — `SCV_EVIDENCE_MIN_SECONDS`

`SCV_PLAIN_KEYS` 등록 (28 → 29), 예시 `_doc` + 기본값 `"4"`. 템플릿 변경 →
digest 재생성.

## Non-Goals

- 영상 후처리(느리게 재인코딩) — 원인은 스펙 속도이고, 재인코딩은 왜곡이다.
- collect-artifacts(report 경로) 경고 — pr-helper 한 곳이면 사람이 본다;
  중복 경고는 소음 (다음 기회).
- Playwright slowMo 강제 설정 — 테스트 자체 속도를 바꾸면 flake 위험;
  유지 시간은 스펙 저자가 넣는다.

## Suggested path

1. test-evidence-pacing.sh Red → lib + 설정 키
2. pr-helper 연결 + 프로토콜 문안
3. Green → 인접 계약 → (pr-evidence-notify 와 같은 PR 로) 회귀 → archive

## Guardrails

- 기존 계약 불변: pr-helper 동작(생성·갱신·첨부·알림), GIF 생성.
- 호스트 중립, whitespace, 순수성 계약. 가이던스 마커 균형(work.md).

## Exit criteria

- 1초짜리 영상 + 기본 임계 → pr-helper dry-run stderr 에 경고. 임계 1 →
  경고 없음. ffprobe 부재 환경 → 무경고·무오류.
- `bash core/tests/test-evidence-pacing.sh` green + `test-pr-notify.sh` green.
