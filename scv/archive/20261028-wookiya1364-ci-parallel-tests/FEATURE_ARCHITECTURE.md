---
title: CI 단축 — 코어 시험을 한 작업 안에서 동시에, 속도 검사는 끝에 혼자
slug: 20261028-wookiya1364-ci-parallel-tests
created_at: 2026-10-28
status: planned
---

# Architecture — CI 단축 — 코어 시험을 한 작업 안에서 동시에, 속도 검사는 끝에 혼자

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

시험 실행 도구 안에서 시험 목록이 결과 표가 되기까지.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  CoreCI[코어 CI 집중 시험 단계] -->|"bash core/tests/run-focused.sh"| ListTests
  CodexCI[codex 래퍼 CI 코어 시험] -->|"격리 사본에서 run-focused.sh"| ListTests
  Dir[(시험 폴더 core/tests)] -->|"test-*.sh 이름순"| ListTests[list_tests]
  ListTests -->|"파일 목록"| Classify[classify]
  Classify -->|"동시에 목록 · 혼자 목록"| RunBatch[run_batch]
  RunBatch -->|"동시 수만큼 겹쳐 실행, 혼자는 끝에"| Logs[(시험별 로그)]
  RunBatch -->|"이름 · 종료 코드 · 초"| Summarize[summarize]
  Summarize -->|"표 · 실패 목록 · 종료 코드"| Report[report]
  Logs -->|"실패한 시험의 로그 전문"| Report
  Report -->|"exit 0 / 1"| CoreCI
  classDef key fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
  class Classify,Summarize key
```

## 2. Position in whole architecture

Where this feature sits in the system. New components highlighted in yellow.

> Source: scv graph (built 2026-10-28)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/tests"
    RunDry[run-dry.sh]
    Autosync[test-autosync.sh]
    Prompting[test-model-prompting.sh]
    Budget[test-help-budget.sh]
    RunFocused[run-focused.sh]:::new
    TestRunFocused[test-run-focused.sh]:::new
  end
  subgraph ".github/workflows"
    CoreCI[core-ci.yml 집중 시험 단계]
  end
  subgraph "codex 래퍼"
    PluginCI[plugin-ci.yml · core-sync.yml]
  end
  CoreCI -->|"공유 회귀"| RunDry
  CoreCI -.->|"집중 시험"| RunFocused
  PluginCI -.->|"격리 사본의 집중 시험"| RunFocused
  RunFocused -.->|"동시에"| Autosync
  RunFocused -.->|"동시에"| Prompting
  RunFocused -.->|"동시에"| Budget
  TestRunFocused -.->|"가짜 시험 폴더로 검사"| RunFocused
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
