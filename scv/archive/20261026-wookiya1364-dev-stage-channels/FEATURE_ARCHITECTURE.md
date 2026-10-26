---
title: SCV 개발 · 스테이징 채널 — 운영 릴리스 없이 바꿔 끼워 받아 확인
slug: 20261026-wookiya1364-dev-stage-channels
created_at: 2026-10-26
status: planned
---

# Architecture — SCV 개발 · 스테이징 채널 — 운영 릴리스 없이 바꿔 끼워 받아 확인

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

채널 바꿔 끼우기(위)와 코어 → 래퍼 채널 동기화(아래).

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  subgraph "채널 바꿔 끼우기 (사용자 컴퓨터)"
    User[사용자] -->|"채널 명령 (개발 · 스테이징 · 운영)"| ChannelCmd[채널 명령]
    ChannelCmd -->|"claude plugin marketplace list --json"| ReadInstalled[① readInstalled]
    ReadInstalled -->|"깔린 상태"| SwitchPlan[④ switchPlan]
    ChannelCmd -->|"채널"| ChannelRef[② channelRef]
    ChannelRef -->|"브랜치"| Source[③ marketplaceSource]
    Source -->|"주소#브랜치"| SwitchPlan
    SwitchPlan -->|"명령 목록"| RunPlan[⑤ runPlan]
    RunPlan -->|"remove → add → update"| ClaudeCLI[(claude / codex CLI)]
  end
  subgraph "채널 동기화 (GitHub)"
    CoreBranch[(코어 develop · stage)] -->|"push"| CorePush[⑥ coreBranchPush]
    CorePush -->|"dispatch(브랜치, 커밋)"| Vendor[⑧ vendorAndCommit]
    Vendor -->|"channelVersion(기준, 채널, 커밋)"| ChVer[⑦ channelVersion]
    Vendor -->|"vendor + 검사 + 반영"| WrapperBranch[(래퍼 develop · stage)]
  end
  ClaudeCLI -.->|"git clone 주소#브랜치"| WrapperBranch
  classDef key fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
  class SwitchPlan,Vendor key
```

## 2. Position in whole architecture

이 기능이 기존 구조 어디에 붙는지. 새 부분은 노란색.

> Source: scv graph (built 2026-10-26)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph ".github/workflows"
    Release[release.yml — 코어 릴리스 · 래퍼 dispatch]
    ChannelPush[채널 push 알림]:::new
  end
  subgraph "core/scripts"
    Mods[mods.sh — 모드 업데이트 출력 모양]
    Channel[channel.sh — 채널 바꿔 끼우기]:::new
  end
  subgraph "core/tests"
    RunDry[run-dry.sh]
    TestChannel[test-channel.sh]:::new
  end
  subgraph "docs"
    WrapperDoc[docs/wrapper-integration.md]
  end
  CHANGELOG[CHANGELOG.md]
  Release --> WrapperDoc
  Release --> CHANGELOG
  Channel -.->|"STEP / RESULT / NEXT 모양 재사용"| Mods
  ChannelPush -.->|"dispatch 단계 재사용"| Release
  TestChannel -.->|"전체 시험에 포함"| RunDry
  Channel -.->|"채널 안내"| WrapperDoc
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
