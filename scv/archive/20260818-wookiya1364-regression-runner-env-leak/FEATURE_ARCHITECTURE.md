---
title: 회귀 러너의 autosync 가드 누수 — 시나리오는 깨끗한 환경에서 돈다
slug: 20260818-wookiya1364-regression-runner-env-leak
created_at: 2026-08-18
status: planned
---

# Architecture — 회귀 러너의 autosync 가드 누수

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

누수 인과 사슬과 이 계획이 끊는 지점.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  Runner[core/scripts/regression.sh — 회귀 러너] -->|"scv_init_paths (실행 시작)"| InitPaths[scv_init_paths]
  InitPaths -->|"scv_autosync 호출"| Autosync[scv_autosync — lib/scvroot.sh]
  Autosync -->|"export SCV_AUTOSYNC_RUNNING=1 (재진입 방지 — 유지)"| Flag[SCV_AUTOSYNC_RUNNING 내부 플래그]
  Flag -.->|"자식 상속 누수 — 이 계획이 끊는 경로"| Scenario[각 슬러그의 How to run 자식 프로세스]
  Runner -->|"슬러그마다 실행"| CleanStep[신규: 자식 환경에서 내부 플래그만 제거]:::new
  CleanStep -->|"SCV_AUTOSYNC_RUNNING 제외, 사용자 env 는 그대로 상속"| Scenario
  Scenario -->|"시나리오 안의 scv_autosync 가 계약대로 동작 (무동작 아님)"| Autosync
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 2. Position in whole architecture

Where this feature sits in the system. New components highlighted in yellow.

> Source: graphify graph (built 2026-08-18)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "회귀 러너 env 누수"
    EnvInheritance[자식 프로세스 환경 상속 누수]
    FixDecision[결정: 러너만 수정 — env -u 상당으로 내부 플래그 제거]
    CleanStep[신규: 시나리오 실행 전 플래그 제거 단계]:::new
  end
  subgraph "회귀 계약 보수"
    Class1[부류 1 — 커밋 전 상태 단언]
  end
  subgraph "문서-가드 일관성"
    DocGuardTest[문서-가드 일관성 테스트]
  end
  FixDecision -->|"rationale_for"| EnvInheritance
  CleanStep -.->|"구현한다"| FixDecision
  CleanStep -.->|"끊는다"| EnvInheritance
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
