---
title: 턴 끝 확인이 멈추지 않게 — 쓴 파일 목록 중복 · 느린 비교 · 끝나지 않는 턴
slug: 20261119-wookiya1364-turn-check-fast-end
created_at: 2026-11-19
status: planned
---

# Architecture — 턴 끝 확인이 멈추지 않게

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

턴 끝 확인 안에서 경로가 흐르는 길. 노란 칸이 이번에 바꾸는 단계.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  OnStop[종료 훅 on-stop.sh] -->|"turn-check.sh end --dir"| ReadState[① readState]
  Touch[도구 앞 훅 touch/settle] -->|"목록에 쓰기 (중복 막기)"| StateDir[(상태 폴더 .turn-plan)]
  StateDir -->|"snap.* · head.* · mine"| ReadState
  ReadState -->|"시작/끝 사진 · git diff h0 h1"| Changed[② changedPaths]
  Changed -->|"경로 줄들"| Filter[③ filterExempt]:::key
  Filter -->|"남은 경로"| Mine[④ mineOnly]:::key
  Mine -->|"내 경로 개수"| Judge[⑤ judge]
  Judge -->|"pass · block · 예산 초과"| WriteEnd[⑥ writeEnd]:::key
  WriteEnd -->|"ended · .turn-plan.log"| StateDir
  WriteEnd -->|"TURN_PLAN: …"| OnStop
  classDef key fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 2. Position in whole architecture

Where this feature sits in the system. New components highlighted in yellow.

> Source: scv graph (built 2026-11-19)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/template/hooks"
    H1[on-stop.sh]
    H2[on-user-prompt.sh]
  end
  subgraph "core/scripts"
    S1[turn-check.sh]
    S2[lib/turn-check.sh]
    S3[pure-bench.sh]
    B1[시간 예산 · 생략 기록]:::new
  end
  subgraph "core/tests"
    T1[test-turn-plan-check.sh]
    T2[test-turn-check-fast-end.sh]:::new
  end
  H1 -->|"end"| S1
  H2 -->|"start"| S1
  S1 -->|"×5 함께 바뀜"| S2
  S1 -->|"×4 함께 바뀜"| T1
  S3 -->|"changed 파일 읽음"| S1
  S1 -.->|"end 안에서"| B1
  T2 -.->|"큰 상태 시험"| S2
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
