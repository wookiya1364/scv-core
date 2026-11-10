---
title: bash 3.2 에서 실패하는 시험 셋 고치기
slug: 20261111-wookiya1364-bash32-tests-three
created_at: 2026-11-11
status: planned
---

# Architecture — bash 3.2 에서 실패하는 시험 셋 고치기

> 두 그림으로 본 이 계획. **구현 전에 읽고 고칠 것** — 그림은 모델이 그렸다.

## 1. Component data flow

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Bash32[맥 기본 bash 3.2] -->|"/bin/bash 시험 파일"| Run[run_under_bash32]
  Run -->|"실패한 줄 · 메시지"| Locate[locate_cause]
  Locate -->|"원인 줄 (시험 | 스크립트)"| Rewrite[portable_rewrite]
  Rewrite -->|"고친 줄"| TG[core/tests/test-graph.sh]
  Rewrite -->|"mapfile → while read"| TGC[tests/test-guard-consistency.sh]
  Rewrite -->|"고친 줄"| TPW[tests/test-promote-wait.sh]
```

## 2. Position in whole architecture

> Source: scv graph (built 2026-11-11)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/tests"
    TG[test-graph.sh]
    RD[run-dry.sh]
  end
  subgraph "tests"
    TGC[test-guard-consistency.sh]
    TPW[test-promote-wait.sh]
  end
  subgraph "core/scripts"
    GR[graph.sh]
  end
  subgraph ".github/workflows"
    CI[CI 맥 · 리눅스]
  end
  TG --> GR
  CI --> TG
  CI --> TGC
  CI --> TPW
```

## 3. Screen mockups

### 시험 셋

```screen
{
  "title": "bash 3.2 시험 셋",
  "diagram": [
    { "label": "순서", "code": "flowchart LR\n  A[\"① bash 3.2 로 돌림\"] --> B[\"② 원인 가름\"]\n  B --> C[\"③ 같은 뜻으로 고침\"]\n  C --> D[\"④ 두 bash 로 다시 돌림\"]" }
  ],
  "functions": [
    { "marker": "1", "title": "bash 3.2 로 돌림", "step": "run_under_bash32", "notes": ["시험 셋의 실패한 줄과 메시지를 모음"] },
    { "marker": "2", "title": "원인 가름", "step": "locate_cause", "notes": ["시험 파일 탓인지 스크립트 탓인지"] },
    { "marker": "3", "title": "같은 뜻으로 고침", "step": "portable_rewrite", "notes": ["확인된 하나: mapfile 을 while read 로"] },
    { "marker": "4", "title": "두 bash 로 다시 돌림", "notes": ["통과 수가 고치기 전 bash 5 결과보다 줄지 않아야 함"] }
  ],
  "validations": { "title": "통과 기준",
    "columns": ["번호", "조건", "결과"],
    "rows": [
      ["1, 4", "세 시험 · bash 3.2", "종료 코드 0"],
      ["4", "세 시험 · bash 5", "종료 코드 0"],
      ["4", "통과 줄 수", "고치기 전보다 줄지 않음 · 건너뜀 0건"]
    ] }
}
```
