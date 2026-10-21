---
title: 드림 — 프롬프트 코치
slug: 20261021-wookiya1364-scv-dreams-prompt-coach
created_at: 2026-10-21
status: planned
---

# Architecture — 드림 — 프롬프트 코치

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  StartHook["① 시작 훅 on-session-start"] -->|"source = clear · compact → dreams.sh --auto &"| Dreams
  PromptHook["② 매 턴 훅 on-user-prompt"] -->|"지난 드림 날짜 ≠ 오늘 → dreams.sh --auto &"| Dreams
  Cmd["③ 명령 scv:dreams"] -->|"dreams.sh"| Dreams
  Dreams["④ dreams.sh (효과부)"] -->|"readTranscripts · readArchives"| Rec[("세션 기록 · scv/archive")]
  Dreams -->|"humanTurns → registerFeatures → bucketPeriods → plansDistribution → ruleTips → pickEvidence"| Lib["⑤ lib/dreams.sh (순수)"]
  Dreams -->|"judgeAdvice(발췌)"| Judge[("⑥ 판정자 명령 SCV_JUDGE_COMMAND")]
  Dreams -->|"renderHtml · renderSummary → writeOutputs"| Out[("⑦ scv/dreams/*.html · latest.json")]
  PromptHook -->|"안 알린 요약 한 줄"| Out
```

## 2. Position in whole architecture

Where this feature sits in the system. New components highlighted in yellow.

> Source: scv graph (built 2026-10-21)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/template"
    UP["core/template/hooks/on-user-prompt.sh"]
    SS["core/template/hooks/on-session-start.sh"]
  end
  subgraph "core/scripts"
    SR["show-real-report.sh"]
    DR["dreams.sh + lib/dreams.sh"]:::new
  end
  subgraph "core/protocols"
    WK["core/protocols/work.md"]
    HP["core/protocols/help.md"]
    DP["protocols/dreams.md"]:::new
  end
  subgraph "core/template/scv"
    ST["scv_settings.example.json"]
  end
  UP -.->|"배경 발동 · 요약 줄"| DR
  SS -.->|"clear · compact 발동"| DR
  DR -.->|"기록 폴더 찾기 · 자동 알림 판별 재사용"| SR
  DP -.->|"SCV_DREAMS · SCV_DREAMS_JUDGE"| ST
  WK -->|"보관 시각 = 목표 도달"| DR
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
