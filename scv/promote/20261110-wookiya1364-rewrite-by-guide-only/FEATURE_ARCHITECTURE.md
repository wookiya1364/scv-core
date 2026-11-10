---
title: 다시 쓰기는 가이드만 — 항목 표 · 낱말 규칙을 없애고 가이드 셋을 넣는다
slug: 20261110-wookiya1364-rewrite-by-guide-only
created_at: 2026-11-10
status: planned
---

# Architecture — 다시 쓰기는 가이드만

> 이 기능을 두 그림으로 본다. **`/scv:work` 전에 읽고 고칠 것** —
> 그림은 모델이 그렸고 틀릴 수 있다.

## 1. Component data flow

한 턴에서 요청이 다시 쓰이고 등록되는 길. 빠지는 것은 점선으로 그렸다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  User[사람의 요청] -->|"원문 그대로"| Hook[매 턴 훅]
  Hook -->|"scv_mp_turn_block: 항목 문구 없는 안내문"| Model[세션의 모델]
  Hook -->|"scv_mp_principle_text: SCV 원칙 세 내용을 답 모양 안내로"| Model
  Guides[(래퍼 가이드 폴더)] -->|"scv_mp_guide_lines: 모델 가이드 + 공통 발췌"| Model
  Model -->|"register: 다시 쓴 요청 + 범위"| Register[등록 명령]
  Register -->|"scv_mp_register_problems: 두 줄이 있는지"| TurnDir[(턴 폴더의 등록 기록)]
  TurnDir -->|"scv_mp_write_gate · scv_mp_scope_forbid"| Guard[쓰기 문]
  TurnDir -->|"다시 쓴 요청 인용이 답 맨 위에 있는지"| Stop[종료 훅]
  Table[항목 표 12줄]:::gone -.->|"없앰: 1:1 견주기"| Model
  Ste[낱말 규칙 15개]:::gone -.->|"없앰: STE 줄"| Model
  Refresh[래퍼 받기 스크립트] -->|"rf_pick_rows: 고른 줄만 받음"| Guides
  classDef gone fill:#3a2a2a,stroke:#f4556d,stroke-dasharray:4 3,color:#fff
```

## 2. Position in whole architecture

이 기능이 닿는 곳. 새로 생기는 것은 노란색이다.

> Source: scv graph (built 2026-11-10)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/scripts"
    MPL[lib/model-prompting.sh]
    MP[model-prompting.sh]
  end
  subgraph "core/protocols"
    PR[help/prompt-refine.md]
  end
  subgraph "core/contracts"
    RP[rewrite-principle.md]
    RS[rewrite-ste.md — 지움]
  end
  subgraph "core/template"
    UP[hooks/on-user-prompt.sh]
    ST[hooks/on-stop.sh]
  end
  subgraph "core/tests"
    TMP[test-model-prompting.sh]
    TNEW[test-rewrite-guide-only.sh]:::new
  end
  subgraph "../scv-claude-code"
    CK[prompting/check.sh]
    RF[prompting/refresh.sh]
    G3[가이드 사본 셋: fable-5-2 · sonnet-5-5 · haiku-5-5]:::new
  end
  MPL -->|"×8 · per-model-prompting"| TMP
  MPL -->|"×7 · prompting-every-turn-checklist"| MP
  MPL -->|"×6 · rewrite-direct-feedback-principle"| PR
  MPL -->|"×5 · answer-bullets"| ST
  MPL -->|"×5 · prompting-first-turn"| UP
  MPL -->|"×3 · rewrite-direct-feedback-principle"| RP
  TNEW -.-> MPL
  TNEW -.-> MP
  G3 -.-> CK
  RF -.-> G3
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
