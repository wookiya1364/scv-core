---
title: 재는 명령과 느려지면 막기 — 순수함수가 기본, 그다음 합성 함수
slug: 20261111-wookiya1364-pure-bench-and-gate
created_at: 2026-11-11
status: planned
---

# Architecture — 재는 명령과 느려지면 막기

> 두 그림으로 본 이 계획. **구현 전에 읽고 고칠 것** — 그림은 모델이 그렸다.

## 1. Component data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Catalog[(순수함수 사전)] -->|"read_catalog"| Targets[pb_targets]
  Changed[턴 끝 검사의 바뀐 파일 목록] -->|"바뀐 함수"| Targets
  Targets -->|"함수 · 예시 입력 · 4배 입력"| Run[run_measured]
  GPU[(GPU 읽는 도구)] -->|"사용률 · 메모리"| Run
  Run -->|"벽시계 · CPU · 메모리 · GPU · 외부 명령 수"| Pick[pb_pick_measure]
  Pick -->|"cpu · wall-gpu · unmeasured"| Scale[pb_scale_ratio]
  Scale -->|"4배 때의 배수"| Compare[pb_compare]
  Compare -->|"판정 줄들"| Base[pb_baseline_next]
  Baseline[(지금 넘는 곳 목록)] -->|"기준 목록"| Base
  Base -->|"실패 줄 · 새 목록"| Render[pb_render]
  Render -->|"표 글"| Out[write_out]
  Choice[(선택 창 답 기록)] -->|"사용자가 정한 변경"| Out
  Out -->|"표 · 종료 코드"| TurnEnd[턴 끝 · 계획 끝]
```

## 2. Position in whole architecture

> Source: scv graph (built 2026-11-11)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/scripts"
    PC[pure-catalog.sh]
    TC[turn-check.sh]
    PB[pure-bench.sh]:::new
    PL[lib/pure-bench.sh]:::new
  end
  subgraph "core/contracts"
    CO[composition.md]
    PU[purity.md]
  end
  subgraph "core/protocols"
    WK[work.md]
  end
  subgraph "core/tests"
    CT[lib/cpu-time.sh]
    TP[test-pure-bench.sh]:::new
  end
  PB -.-> PC
  PB -.-> PL
  TC -.-> PB
  WK -.-> PB
  CO -.-> PB
  TP -.-> PB
  PL -.-> CT
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 3. Screen mockups

### 재는 명령의 표

```screen
{
  "title": "재는 명령 — 결과 표",
  "body": [
    { "type": "header", "title": "순수함수 재기", "subtitle": "판정 잣대는 실제로 쓴 것으로 고른다" },
    { "type": "table", "marker": "1", "columns": ["함수", "잣대", "한 번에 드는 값", "메모리 최고", "GPU", "외부 명령 수", "4배 입력"],
      "rows": [
        ["scv_tc_words", { "badge": "cpu", "tone": "muted" }, "0.42ms", "값", "안 씀", "0", { "badge": "12.6배", "tone": "danger" }],
        ["scv_tc_diff", { "badge": "cpu", "tone": "muted" }, "4.6ms", "값", "안 씀", "값", { "badge": "4.4배", "tone": "good" }],
        ["GPU 작업(셸로 띄움)", { "badge": "wall-gpu", "tone": "info" }, "8.3s", "241MB", "92% · 1.1GB", "값", "값"],
        ["GPU 도구가 없는 곳의 GPU 작업", { "badge": "재지 못함", "tone": "warn" }, "값", "값", "재지 못함", "값", "값"]
      ] },
    { "type": "text", "marker": "2", "value": "잰 수 · 못 잰 수와 이유" }
  ],
  "functions": [
    { "marker": "1", "title": "결과 표", "step": "pb_render", "notes": ["숫자는 2026-11-11 에 실제로 잰 값, '값'은 구현 뒤에 채워질 칸"] },
    { "marker": "2", "title": "요약 줄", "step": "pb_render", "notes": ["재지 못한 것은 통과로 세지 않음"] }
  ],
  "validations": { "title": "막는 경우 · 지나가는 경우",
    "columns": ["조건", "결과", "보이는 것"],
    "rows": [
      ["고치기 전보다 한도 넘게 느려짐 · 메모리를 더 씀", "실패", "함수 이름 · 앞뒤 값 · 배수"],
      ["지금 넘는 곳 목록이 늘어남", "실패", "새로 넘은 함수"],
      ["한도를 넘었지만 선택 창 답이 있음", "통과", "답이 계획 기록에 남음"],
      ["GPU 를 썼는데 읽을 도구가 없음", "재지 못함", "통과로 세지 않음"],
      ["순수함수를 안 고친 턴", "돌지 않음", "없음"]
    ] }
}
```
