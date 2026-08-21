---
title: "기록 훅의 바이트 자르기가 한글을 반으로 — journal 은 항상 온전한 UTF-8"
slug: 20260821-wookiya1364-journal-utf8-tail
author: "wookiya1364"
created_at: 2026-08-21
status: done
kind: feature
lang: korean
tags: [hooks, journal, encoding]
raw_sources:
  - scv/conversations/20260821-154845-journal-utf8-tail.md
refs: []
supersedes: []
scope:
  - "core/template/hooks/on-stop.sh"
  - "core/tests/test-journal.sh"
  - "CHANGELOG.md"
invariants:
  - "기록 훅은 비차단 — 어떤 실패에도 exit 0, scv/journal/ 밖에 쓰지 않는다"
  - "답변 꼬리의 길이 상한(40줄·4000바이트 근처)은 유지 — 캡을 없애지 않는다"
  - "iconv·python3 둘 다 없으면 지금처럼 그대로 붙인다(best effort)"
---

# 기록 훅의 바이트 자르기가 한글을 반으로

## Summary

어시스턴트 답변을 일지에 남기는 훅(on-stop.sh)이 마지막 4000**바이트**를 잘라
붙인다. 한글·일본어·이모지는 한 글자가 3–4바이트라 그 자리에서 글자가 반으로
잘리고, 일지 첫머리에 깨진 바이트 하나가 남는다. 편집기는 그 한 바이트 때문에
파일 전체를 다른 인코딩으로 읽어 "한글이 다 깨진" 것처럼 보여 준다(실제
프로젝트에서 59KB 중 1곳, 16건 중 1건 — 실측). 바이트 캡 뒤에 반쪽 시퀀스를
떨어내면 된다.

## Goals / Non-Goals

- **Goals**: 캡을 적용한 뒤 선두의 반쪽 멀티바이트 시퀀스를 떨어낸다(iconv -c,
  없으면 python3, 둘 다 없으면 그대로). 다국어 긴 답변 테스트 1건(일지가 유효한
  UTF-8 이고 꼬리가 살아 있다). 0.31.2 패치 릴리스.
- **Non-Goals**: 캡 크기 변경, journal-append.sh 수정, 기존 일지 자동 복구(이번
  건은 손으로 1바이트 제거).

## Approach Overview

`tail -n 40 | tail -c 4000` 뒤에 `iconv -c -f UTF-8 -t UTF-8` 을 통과시킨다. GNU
iconv 는 바이트를 버리면 exit 1 을 내므로 **출력으로 판단**한다(빈 출력이 아니면
채택). iconv 가 없으면 python3 `decode("utf-8","ignore")`, 둘 다 없으면 원문.

## Guardrails

- 비차단 유지, journal 밖 쓰기 금지, 호스트 이름 금지, git 상태 단언 금지.
- 떨어내는 것은 반쪽 시퀀스뿐 — 정상 글자는 한 자도 잃지 않는다.

## Exit criteria

- TESTS exit 0. 0.31.2 릴리스 → 래퍼 두 곳 핀·릴리스.

## Suggested path

1. on-stop.sh 수정. 2. test-journal [6u]. 3. CHANGELOG. 4. archive → PR → 0.31.2.

## Related Documents

- 선행: `scv/archive/20260804-wookiya1364-team-journal/PLAN.md`

## Risks / Open Questions

- journal-append.sh 의 redaction 도 바이트 단위라면 같은 문제가 있을 수 있다 — 이번
  실측에서는 해당 없음(잘린 곳은 캡 지점 1곳뿐). 재발하면 그쪽을 본다.

## Links

- Raw originals: (frontmatter 참조)
