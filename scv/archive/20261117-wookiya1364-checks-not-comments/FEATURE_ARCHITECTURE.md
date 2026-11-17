---
title: 글 대신 검사 — 매 턴 글 덜기 · 정정을 검사로 제안 · 임시방편 주석 알림 · 대시보드 단계 증거 · 순수 함수 재사용 검사
slug: 20261117-wookiya1364-checks-not-comments
created_at: 2026-11-17
status: planned
---

# Architecture — 글 대신 검사

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  subgraph S1["1 매 턴 글 덜기"]
    readTurnText[readTurnText] -->|"줄 목록"| matchRuleToCheck[matchRuleToCheck]
    matchRuleToCheck -->|"대조 표"| dropCoveredLines[dropCoveredLines]
  end
  subgraph S2["2 정정 → 검사 제안"]
    Hook[매 턴 훅] -->|"직전 사람 턴 글"| detectCorrection[detectCorrection]
    detectCorrection -->|"scv_show_real_is_correction → 0/1"| correctionNotice[correctionNotice]
    correctionNotice -->|"안내 한 줄"| Hook
  end
  subgraph S3["3 임시방편 주석 알림"]
    PlanEnd[pure-bench.sh plan-end] -->|"git diff"| addedCommentLines[addedCommentLines]
    addedCommentLines -->|"추가 주석 줄"| flagWorkaround[flagWorkaround]
    flagWorkaround -->|"파일:줄 알림 (막지 않음)"| PlanEnd
  end
  subgraph S4["4 대시보드 단계 증거 · 실제 진행"]
    StepTool[scv_step 단계 보고] -->|"done + 증거 경로 · 출력"| judgeEvidence[judgeEvidence]
    Files[(증거 파일 · 로그 파일)] -->|"있음 · 바뀐 시각"| judgeEvidence
    judgeEvidence -->|"거절 이유"| StepTool
    judgeEvidence -->|"받은 증거"| stepDetail[stepDetail]
    Files -->|"로그 끝 줄 · 진행률"| stepDetail
    stepDetail -->|"노드 상세 (지금 하는 일 칸 대체)"| Pane[대시보드 노드 상세]
  end
  subgraph S5["5 순수 함수 재사용 검사"]
    PlanEnd -->|"git diff"| addedFunctions[addedFunctions]
    addedFunctions -->|"새 함수 · 표식"| flagUnmarked[flagUnmarked]
    addedFunctions -->|"새 순수 함수"| similarEntries[similarEntries]
    Catalog[(순수 함수 사전 · 중복 예외)] -->|"닮은 후보"| similarEntries
    similarEntries -->|"예시 입력별 출력 짝"| sameBehavior[sameBehavior]
    flagUnmarked -->|"막힘"| PlanEnd
    sameBehavior -->|"같으면 막힘"| PlanEnd
  end
  dropCoveredLines -.->|"비운 자리"| correctionNotice
```

## 2. Position in whole architecture

> Source: scv graph (built 2026-11-17)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core (scv-core)"
    OnPrompt[core/template/hooks/on-user-prompt.sh]
    WorkProto[core/protocols/work.md]
    RunDry[core/tests/run-dry.sh]
    TurnText[매 턴 글 덜기]:::new
    Correction[정정 제안 안내]:::new
    CommentFlag[임시방편 주석 알림]:::new
    FnCheck[새 함수 표식 · 닮은 함수 검사]:::new
  end
  subgraph "../scv-claude-code · ../scv-codex"
    Wrappers[래퍼 사본]
  end
  subgraph "../scv-mods"
    Dash[scv-dashboard 모드]
    Evidence[노드 상세 · 증거 거절]:::new
  end
  OnPrompt --> WorkProto
  RunDry --> OnPrompt
  TurnText -.-> OnPrompt
  Correction -.-> OnPrompt
  CommentFlag -.-> WorkProto
  FnCheck -.-> WorkProto
  Evidence -.-> Wrappers
  OnPrompt --> Wrappers
  Evidence -.-> Dash
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
