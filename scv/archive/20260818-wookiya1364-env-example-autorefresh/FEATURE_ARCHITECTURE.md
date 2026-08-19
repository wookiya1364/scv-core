---
title: .env.example.scv 자동 최신화 — root 불가침의 명명된 예외
slug: 20260818-wookiya1364-env-example-autorefresh
created_at: 2026-08-18
status: planned
---

# Architecture — .env.example.scv 자동 최신화 — root 불가침의 명명된 예외

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

How this feature's components interact.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  ScvAutosync[scv_autosync — lib/scvroot.sh] -->|"프로젝트 스탬프 < payload TEMPLATE_VERSION 이면 sync 실행"| TemplatePass[sync.sh 템플릿 패스]
  TemplatePass -->|"scv/ 심볼링크면 전체 스킵 (WARN 하나) — 이 단계 포함"| EnvStep[신규 .env.example.scv 단계]:::new
  TemplateSrc[core/template/.env.example.scv] -->|"read (최신 템플릿)"| EnvStep
  EnvStep -->|"내용 비교 — 같으면 무동작, 부재면 재생성"| RootFile[프로젝트 루트 .env.example.scv]
  EnvStep -->|"git show HEAD:.env.example.scv 대조"| GitRepo[(git 저장소 HEAD)]
  EnvStep -->|"HEAD 복원 가능 → 최신 템플릿으로 교체"| RootFile
  EnvStep -->|"HEAD 복원 불가 → DIRTY 거부 (--force 만 오버라이드)"| Partial[PARTIAL 보고]
  Partial -->|"스탬프 미전진 — 다음 액션마다 재시도"| Stamp[TEMPLATE_VERSION 스탬프]
  TemplatePass -->|"거부 0건이면 스탬프 전진"| Stamp
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 2. Position in whole architecture

Where this feature sits in the system. New components highlighted in yellow.

> Source: graphify graph (built 2026-08-18)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "Sync 자동화·더티 거부"
    ScvAutosync[scv_autosync — 다음 액션이 격차를 메운다]
    DirtyRefusal[백업 대신 더티 거부]
    AutosyncRails[autosync 가드레일 — 수화 금지·pre-2.x 제외]
    EnvStep[신규 .env.example.scv 단계]:::new
  end
  subgraph "Effort Governor 판정"
    GovernorSection[work.md·codegen.md 의 Effort governor 절]
    EffortClass[core/scripts/effort-class.sh]
  end
  subgraph "문서-가드 일관성"
    DocGuardTest[문서-가드 일관성 테스트]
  end
  DirtyRefusal -->|"references"| AutosyncRails
  ScvAutosync -->|"references"| AutosyncRails
  EffortClass -->|"calls"| GovernorSection
  EnvStep -.->|"HEAD 대조·DIRTY 장치 재사용"| DirtyRefusal
  EnvStep -.->|"autosync 경로에 편입"| ScvAutosync
  EnvStep -.->|"미채택·pre-2.x 게이트 준수"| AutosyncRails
  EnvStep -.->|"SCV_EFFORT_MODE 문서 블록 전파"| GovernorSection
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
