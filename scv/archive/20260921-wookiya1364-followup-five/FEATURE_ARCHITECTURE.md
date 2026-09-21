---
title: 후속 다섯 — 문구 앵커, 경계 계약 한 곳, 재실행 시간 초과 안내
slug: 20260921-wookiya1364-followup-five
created_at: 2026-09-21
status: planned
---

# Architecture — 후속 다섯

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  subgraph "가드 예외 검사 (tests/test-guard-consistency.sh)"
    Guard[("contracts/guard.md guard:exceptions")] -->|"block exceptions"| Parse["parse_anchor"]:::new
    Parse -->|"(파일, 문구)"| Lines["phrase_lines (grep -cF)"]:::new
    Lines -->|"줄 수·본문"| Judge["judge_anchor → ok|stale|ambiguous"]:::new
    Judge -->|"판정"| Report["[3] pass/fail"]
    Sweep["[2] PHRASES 순회"] -->|"(rel, text)"| Match["anchor_matches(rel, text)"]:::new
    Parse -->|"앵커들"| Match
  end
  subgraph "경계 계약 (한 곳)"
    B["contracts/boundaries.md"]:::new
    Codegen["codegen.md"] -.->|"포인터 한 줄"| B
    Work["work.md"] -.->|"포인터 한 줄"| B
    Reg["regression.md"] -.->|"포인터 한 줄"| B
    RunDry["run-dry.sh [11s]"] -->|"assert 포인터"| Codegen
  end
  subgraph "증거 재실행 (pr-helper.sh)"
    PRH["pr-helper"] -->|"run-plan-tests --timeout N"| RPT["run-plan-tests.sh"]
    RPT -->|"rc (124 = timeout)"| Msg["rc → 문구"]:::new
    Msg -->|"stderr 한 줄"| PRH
  end
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 2. Position in whole architecture

> Source: scv graph (built 2026-09-21)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/contracts"
    G["guard.md"]
    Rc["recording.md"]
    Dc["decisions.md"]
    Bd["boundaries.md"]:::new
  end
  subgraph "core/protocols"
    C["codegen.md"]
    W["work.md"]
    R["regression.md"]
  end
  subgraph "core/scripts"
    PH["pr-helper.sh"]
    RP["run-plan-tests.sh"]
  end
  subgraph "tests · core/tests"
    TG["tests/test-guard-consistency.sh"]
    RD["run-dry.sh"]
    TA["test-attachments-scope.sh"]
    TRC["test-rule-constitution.sh"]
  end
  TG --> G
  C --> Rc
  W --> Dc
  R --> Dc
  C -.-> Bd
  W -.-> Bd
  R -.-> Bd
  RD --> C
  PH --> RP
  TA --> PH
  TRC --> C
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 3. Screen mockups

화면 없는 변경. 구성은 위 두 그림, 번호별 상세는 아래 한 장.

```screen
{
  "title": "가드 예외 앵커 — 문구 기준",
  "diagram": [
    { "label": "구성", "code": "flowchart LR\n  A[(\"① guard.md 예외 6줄\")] --> B[\"② parse_anchor\"] --> C[\"③ phrase_lines\"] --> D[\"④ judge_anchor\"] --> E[\"⑤ 보고\"]\n  F[\"⑥ [2] 문구 순회\"] --> G[\"⑦ anchor_matches\"]\n  B --> G" },
    { "label": "순서", "code": "sequenceDiagram\n  autonumber\n  participant T as test-guard-consistency.sh\n  participant F as 규칙 문서들\n  T->>T: block exceptions → 앵커 6\n  loop 앵커마다\n    T->>F: grep -cF \"문구\"\n    F-->>T: 일치 줄 수\n    alt 0줄\n      T-->>T: stale (문구 사라짐)\n    else 2줄 이상\n      T-->>T: ambiguous\n    else 1줄인데 PHRASES 미일치\n      T-->>T: stale (예외가 필요 없는 줄)\n    else\n      T-->>T: ok\n    end\n  end" }
  ],
  "functions": [
    { "marker": "2", "title": "앵커 파싱", "step": "parse_anchor", "notes": ["받는 값: 'path:\"문구\" — reason' 한 줄", "돌려주는 값: 파일, 문구", "순수"] },
    { "marker": "4", "title": "판정", "step": "judge_anchor", "notes": ["받는 값: 일치 줄 수, 줄 본문", "돌려주는 값: ok | stale | ambiguous", "순수"] },
    { "marker": "7", "title": "예외 대조", "step": "anchor_matches", "notes": ["받는 값: 파일, 줄 본문", "같은 파일의 앵커 문구를 본문이 담으면 예외", "줄 번호를 보지 않는다"] }
  ],
  "validations": {
    "title": "실패 · 응답 표",
    "columns": ["번호", "조건", "결과", "메시지"],
    "rows": [
      ["④", "문구가 0줄", "FAIL", "<anchor> (the excused phrase is no longer there)"],
      ["④", "문구가 2줄 이상", "FAIL", "<anchor> (ambiguous — phrase matches N lines)"],
      ["④", "1줄이나 검사 어휘 미일치", "FAIL", "<anchor> (line no longer needs an exception)"],
      ["⑦", "문구 순회 적중인데 앵커 없음", "FAIL", "<rel>:<line>: <text>"]
    ]
  }
}
