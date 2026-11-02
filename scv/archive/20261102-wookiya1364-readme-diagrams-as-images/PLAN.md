---
title: README 그림을 이미지로 — 휴대폰에서도 보이게
slug: 20261102-wookiya1364-readme-diagrams-as-images
author: wookiya1364
created_at: 2026-11-02
status: testing
kind: feature
lang: korean
tags: [docs, readme]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs: []
invariants:
  - "README 검사의 다른 규칙(명령 · 설정 · 링크 · 주제 · GIF · 언어판 일치)은 그대로"
  - "scv-mods 의 머메이드 규칙(mermaid 1 · seq /scv-mirror)은 그대로"
---

# README 그림을 이미지로 — 휴대폰에서도 보이게

## Summary

GitHub 휴대폰 앱은 머메이드를 그리지 않고 코드로 보인다(웹만 그림). 코어 · claude · codex README(영 · 한 · 일)의
머메이드 그림 18개를 같은 내용의 SVG 이미지로 바꿔 휴대폰 · 웹 어디서나 보이게 하고, 원본은 파일로 따로 둔다.

## Goals / Non-Goals

- **Goals**
  - 세 저장소 README 9개의 머메이드 블록 18개 → `<img>` SVG 18개 (그림 내용 · 어두운 배경 그대로)
  - 그림마다 원본 `.mmd` 파일을 저장소에 두고, 다시 뽑는 명령 한 줄을 남긴다
  - README 검사: core · claude · codex 는 '머메이드 2개 이상' 대신 '그림 이미지 2개 이상, 이미지마다 같은 이름의 `.mmd` 원본 있음'
- **Non-Goals**
  - docs/ 아래 문서(구조 문서 등)의 머메이드 — 이번엔 README 만
  - scv-mods 저장소 README
  - 그림 내용 · 문구 바꾸기

## Approach Overview

1. 각 README 의 머메이드 블록을 꺼내 저장소의 `assets/diagrams/<이름>.<언어>.mmd` 로 옮긴다.
2. mermaid-cli 로 같은 이름의 `.svg` 를 뽑는다(어두운 배경 고정). 다시 뽑는 명령은 README 검사 도구 옆 안내 한 줄.
3. README 의 머메이드 블록 자리에 `<img src="assets/diagrams/…svg" alt="…">` 를 넣는다.
4. 코어 `tools/check-readme.sh` 의 그림 규칙에 `image <최소 수>` 종류를 더하고 core · claude · codex 를 그것으로 바꾼다.
5. 코어 PR 먼저 → 릴리스 때 래퍼에 검사 도구가 들어간 뒤 래퍼 README 를 바꾼다(래퍼 CI 는 vendored 검사로 돈다).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  diagram_images_of,   // README 본문 → 그림 이미지 경로 목록
  sources_missing,     // 경로 목록 + 있는 파일 → 원본(.mmd)이 없는 이미지
  missing_diagrams,    // 본문 + 필요 규칙 → 모자란 그림 설명 (✖ 줄)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `diagram_images_of` | 코드 블록 밖 `assets/diagrams/*.svg` 참조를 뽑는다 | README 본문 → 경로 줄 | 순수 |
| 2 | `sources_missing` | 이미지마다 같은 이름 `.mmd` 가 있는지 본다 | 경로 줄 + 파일 존재 → 빠진 원본 | 순수(존재 여부는 입구에서 읽어 넘김) |
| 3 | `missing_diagrams` | 규칙(`image 2`)과 비교해 ✖ 줄을 만든다 | 본문 + 규칙 → ✖ 줄 | 순수 |
| 4 | 렌더 | `.mmd` → `.svg` (mermaid-cli) | 원본 파일 → 이미지 파일 | 부수효과 (출구) |

- 부수효과 위치: 파일 존재 확인(검사 입구), SVG 렌더(작업 때 한 번, 출구)
- 재사용: 기존 `links_of`(이미지 경로 링크 검사)와 `missing_diagrams` 의 case 에 종류 하나 추가

## Guardrails

- README 의 다른 글 · 표 · GIF 는 건드리지 않는다 — 머메이드 블록 자리만 바꾼다
- README 검사의 다른 규칙 · scv-mods 규칙은 그대로
- 래퍼 vendored 코어는 손으로 고치지 않는다 — 코어 릴리스 → 봇 동기화로만
- 맥 · 리눅스 둘 다 같은 결과

## Exit criteria

- All TESTS.md scenarios pass
- 세 저장소 main 의 README 9개에 머메이드 블록 0개, 그림 이미지 18개
- 휴대폰 GitHub 앱에서 그림이 보인다(사용자 확인)

## Suggested path

1. 코어 README 3판의 그림 6개를 원본 · SVG 로 빼고 README 를 바꾼다 — 머메이드 블록을 원본 파일과 이미지로 옮김
2. `check-readme.sh` 에 이미지 규칙을 더하고 core · claude · codex 규칙을 바꾼다 — `diagram_images_of`, `sources_missing`, `missing_diagrams`
3. 검사 시험(test-check-readme)에 이미지 규칙 사례를 더한다 — 원본 빠짐 · 이미지 모자람이 빨갛게 나오는지 확인
4. 코어 PR · 릴리스 뒤, 두 래퍼 README 그림 12개를 같은 방식으로 바꾼다 — 머메이드 블록을 원본 파일과 이미지로 옮김

## Related Documents

- `tools/check-readme.sh`, `tests/test-check-readme.sh`

## Risks / Open Questions

- mermaid-cli 는 크롬이 필요하다 — 렌더는 작업하는 맥에서 한 번, CI 는 렌더하지 않고 파일 존재만 본다. 원본을 고치고 SVG 를 안 다시 뽑으면 둘이 어긋난다(검사는 못 잡음 — 다시 뽑는 명령을 README 검사 실패 안내에 적는다).
- GitHub 이 SVG 의 글꼴을 다르게 그릴 수 있다 — 첫 이미지를 휴대폰 · 웹에서 보고 진행.
- 래퍼 CI 는 다음 코어 릴리스 전까지 옛 검사(머메이드 2개)로 돈다 — 래퍼 README 는 코어 릴리스 뒤에 바꾼다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
