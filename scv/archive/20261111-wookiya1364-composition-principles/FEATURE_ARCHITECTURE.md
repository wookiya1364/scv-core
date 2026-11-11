---
title: 합성 설계 원칙을 SCV 계약에 넣기 — 원칙 · 언어별 표 · 체크리스트
slug: 20261111-wookiya1364-composition-principles
created_at: 2026-11-11
status: planned
---

# Architecture — 합성 설계 원칙을 SCV 계약에 넣기

> 두 그림으로 본 이 계획. **구현 전에 읽고 고칠 것** — 그림은 모델이 그렸다.

## 1. Component data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Guide[사용자가 준 합성 설계 가이드] -->|"3장 원칙 · 5장 표 · 6장 체크리스트"| Contract[contracts/composition.md]
  Purity[contracts/purity.md] -->|"가리키는 한 줄"| Contract
  Contract -->|"체크리스트 10개"| Template[계획 템플릿의 순수함수 절]
  Template -->|"번호 · 답 · 근거 표"| PlanDoc[PLAN.md]
  PlanDoc -->|"read_plan"| Rows[checklist_rows]
  Rows -->|"줄들(번호 · 답 · 근거)"| Problems[checklist_problems]
  Problems -->|"표 없음 · 답 없음 · 근거 없음"| Warn[render_warnings]
  Warn -->|"경고 글 (막지 않음)"| Deck[기획서 만들기]
  Work[작업 규약의 보관 전 단계] -->|"실제 코드로 다시 답함"| PlanDoc
```

## 2. Position in whole architecture

> Source: scv graph (built 2026-11-11)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/contracts"
    PU[purity.md]
    CO[composition.md]:::new
  end
  subgraph "core/protocols"
    PR[promote.md]
    WK[work.md]
  end
  subgraph "core/DeckUI"
    DL[기획서 검사]
    CR[checklist_rows · checklist_problems]:::new
  end
  subgraph "core/tests"
    TB[test-help-budget.sh]
    TN[test-composition-principles.sh]:::new
  end
  PU -.-> CO
  PR -.-> CO
  WK -.-> CO
  CR -.-> DL
  TN -.-> CO
  TN -.-> DL
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 3. Screen mockups

### 계획서의 체크리스트 표

```screen
{
  "title": "계획서 — 순수함수 · 파이프라인 절",
  "body": [
    { "type": "header", "title": "합성 설계 체크리스트", "subtitle": "답마다 근거(파일과 줄) 또는 '해당 없음'과 이유" },
    { "type": "table", "marker": "1", "columns": ["#", "물음", "답", "근거"],
      "rows": [
        ["1", "각 단계가 요소 단위 단항 순수 함수인가", "예", "파일과 줄"],
        ["3", "요소 단위로 먼저 합성한 뒤 순회는 한 번만 하는가", "예", "파일과 줄"],
        ["7", "부수효과가 파이프라인 양 끝에만 있는가", "예", "파일과 줄"],
        ["10", "핫패스는 측정한 뒤에 최적화했는가", "해당 없음", "이유"]
      ] }
  ],
  "functions": [
    { "marker": "1", "title": "체크리스트 표", "step": "checklist_rows", "notes": ["계획을 쓸 때 한 번, 끝낼 때 실제 코드로 다시 한 번 채움"] }
  ],
  "validations": [
    { "marker": "1", "when": "기획서 만들 때", "condition": "체크리스트 표가 없음", "message": "합성 설계 체크리스트가 없습니다", "shownAs": "경고 한 줄(막지 않음)" },
    { "marker": "1", "when": "기획서 만들 때", "condition": "답은 있는데 근거 칸이 빔", "message": "근거가 없는 답: 번호들", "shownAs": "경고 한 줄(막지 않음)" }
  ]
}
```
