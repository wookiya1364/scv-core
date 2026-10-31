---
title: 매 턴 훅 속도 — 같은 판단은 한 번, 설정은 파일당 한 번 읽기
slug: 20261030-wookiya1364-hook-dedupe-settings-read
created_at: 2026-10-30
status: planned
---

# Architecture — 매 턴 훅 속도 — 같은 판단은 한 번, 설정은 파일당 한 번 읽기

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

매 턴 훅이 입력을 한 번 읽고, 사람 메시지 판단과 선택 창 상태를 한 번 구해 실체 보여 주기 안내에 넘긴다. 설정은 파일마다 한 번 펼쳐 둔 표에서 찾는다. ①–⑦ 은 계획의 파이프라인 단계 번호다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Host[Claude Code 호스트] -->|"UserPromptSubmit JSON"| Hook["① 매 턴 훅 on-user-prompt.sh"]
  Hook -->|"prompt (한 번)"| Kind["② model-prompting.sh kind"]
  Hook -->|"line · tool · unattended (한 번)"| Gate["③ choice-gate.sh"]
  Hook -->|"kind · tool · unattended 넘김"| ShowReal["④ show-real.sh line"]
  ShowReal -->|"scv_show_real_rule(...)"| Rule[lib/show-real.sh]
  Gate -->|"settings_get SCV_CHOICE_GATE"| Settings[lib/settings.sh settings_get]
  Hook -->|"settings_get SCV_* (16번)"| Settings
  Settings -->|"_settings_slurp(file)"| Files[(scv_settings.json · secret.json)]
  Settings -->|"jq 한 번: 파일 → 키·값 표"| Index["⑤ indexSettings"]
  Index -->|"표 · 키"| Lookup["⑥ lookupSetting"]
  Hook -->|"모은 줄"| Out["⑦ 표준출력"]
  classDef key fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
  class Index,Lookup key
```

## 2. Position in whole architecture

Where this feature sits in the system. New components highlighted in yellow.

> Source: scv graph (built 2026-10-30)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/template"
    Hook[hooks/on-user-prompt.sh]
  end
  subgraph "core/scripts"
    Settings[lib/settings.sh]
    MP[model-prompting.sh]
    CG[choice-gate.sh]
    SR[show-real.sh]
    Index[펼친 설정 표 indexSettings]:::new
  end
  subgraph "core/tests"
    TMP[test-model-prompting.sh]
    TSR[test-show-real.sh]
    TS[test-settings.sh]
    TD[test-hook-dedupe.sh]:::new
  end
  Hook -->|"×7 · plain-answers-enforcement"| TMP
  Hook -->|"×3 · plain-answers-enforcement"| TSR
  Hook -->|"×3 · plain-answers-enforcement"| TS
  Settings -->|"×3 · scv-always-on"| Hook
  Hook --> MP
  Hook --> CG
  Hook --> SR
  Settings -.-> Index
  TD -.-> Hook
  TD -.-> Settings
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```
