---
title: 순수함수 목록 — 만들기 전에 목록에서 찾아 재사용
slug: 20261101-wookiya1364-pure-function-catalog
created_at: 2026-11-01
status: planned
---

# Architecture — 순수함수 목록 — 만들기 전에 목록에서 찾아 재사용

> Two-diagram view of this feature. **Review and edit before `/scv:work`** —
> diagrams are LLM-generated and may have inaccuracies.

## 1. Component data flow

코드 옆 주석 한 곳에서 시작해 검사와 사전 생성으로 갈라진다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Src[(코어 스크립트 주석)] -->|"readSources(경로들)"| Extract[extractEntries]
  Extract -->|"항목들"| Validate[validateEntries]
  Extract -->|"항목들"| Run[runExamples]
  Run -->|"실제 출력"| Check[checkExamples]
  Extract -->|"항목들 + 공통 입력"| Finger[fingerprint]
  Finger -->|"지문들"| Dup[findDuplicates]
  Except[(중복 예외 목록)] -->|"짝 + 이유"| Dup
  Extract -->|"항목들"| Group[groupByKind]
  Group -->|"묶음들"| Render[renderCatalog]
  Render -->|"차례 + 종류 파일 글"| Write[writeOrCompare]
  Write -->|"생성 / 어긋남 판정"| Catalog[(종류별 사전 + 차례)]
  Catalog -->|"차례 → 종류 파일 하나"| Work[work · codegen 규약]
```

## 2. Position in whole architecture

새 부분(노랑)은 기존 순수 검사기 곁에 붙고, 구현 규약과 CI 가 결과를 읽는다.

> Source: scv graph (built 2026-11-01)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "core/contracts"
    Purity[purity.md 순수부 계약]
  end
  subgraph "core/scripts"
    Checker[check-purity.sh 순수 검사기]
    Libs[lib 표식 함수 234개]
    CatalogGen[사전 생성 · 중복 검사]:::new
    Catalog[(종류별 사전 + 차례)]:::new
  end
  subgraph "core/protocols"
    Work[work.md]
    Codegen[codegen.md]
  end
  subgraph ".github/workflows"
    CI[CI]
  end
  Purity --> Checker
  Checker -->|"표식 찾기"| Libs
  Checker -.->|"표식 목록 재사용"| CatalogGen
  Libs -.->|"역할 · 종류 · 예시 주석"| CatalogGen
  CatalogGen -.->|"생성"| Catalog
  Work -.->|"새 함수 전에 읽기"| Catalog
  Codegen -.->|"새 함수 전에 읽기"| Catalog
  CI -.->|"어긋남 · 중복 의심이면 실패"| CatalogGen
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 3. Screen mockups

### 사전 생성 · 중복 검사 (화면 없음)

```screen
{
  "title": "순수함수 사전 · 중복 검사",
  "diagram": [
    { "label": "구성", "code": "flowchart LR\n  S[\"주석\"] --> A[\"① 항목 뽑기\"]\n  A --> B[\"② 칸 검사\"]\n  A --> C[\"③ 예시 실행 · 비교\"]\n  A --> D[\"④ 지문 · 중복 판정\"]\n  A --> E[\"⑤ 종류별 묶기 · 사전 쓰기\"]\n  E --> F[(\"⑥ 사전\")]" },
    { "label": "순서", "code": "sequenceDiagram\n  autonumber\n  participant CI\n  participant G as 검사기\n  participant L as 표식 함수들\n  CI->>G: 검사 실행\n  G->>L: 예시 · 공통 입력으로 호출\n  L-->>G: 출력\n  alt 빈 칸 · 틀린 예시 · 중복 의심 · 사전 낡음\n    G-->>CI: 실패 + 이유\n  else 모두 맞음\n    G-->>CI: 통과\n  end" }
  ],
  "functions": [
    { "marker": "1", "title": "항목 뽑기", "step": "extractEntries", "notes": ["받는 값: 스크립트 내용", "돌려주는 값: 이름 · 위치 · 표식 · 역할 · 종류 · 예시"] },
    { "marker": "2", "title": "칸 검사", "step": "validateEntries", "notes": ["역할 · 종류 · 예시 중 빠진 칸, 목록에 없는 종류를 찾음"] },
    { "marker": "3", "title": "예시 실행 · 비교", "step": "checkExamples", "notes": ["적힌 출력과 실제 출력이 다르면 실패"] },
    { "marker": "4", "title": "지문 · 중복 판정", "step": "findDuplicates", "notes": ["같은 개수 인자 함수끼리 공통 입력 출력 비교", "예외 목록은 이유가 있어야 인정"] },
    { "marker": "5", "title": "종류별 묶기 · 사전 쓰기", "step": "renderCatalog", "notes": ["차례 + 종류 파일", "한도 넘는 종류는 세부 종류로 쪼갬"] },
    { "marker": "6", "title": "사전", "step": "writeOrCompare", "notes": ["생성물 — 손으로 고치면 CI 가 어긋남으로 잡음"] }
  ],
  "validations": {
    "title": "실패 · 응답 표",
    "columns": ["번호", "조건", "응답", "메시지"],
    "rows": [
      ["2", "역할 · 종류 · 예시 빠짐", "실패", "함수 이름 + 빠진 칸"],
      ["2", "목록에 없는 종류", "실패", "허용 종류 목록 안내"],
      ["3", "예시 출력이 실제와 다름", "실패", "적힌 값 · 실제 값"],
      ["4", "공통 입력 출력이 전부 같은 짝", "실패", "중복 의심 짝 · 예외 등록법"],
      ["4", "이유 없는 예외", "실패", "이유를 적으라는 안내"],
      ["6", "사전이 코드와 어긋남", "실패", "다시 생성하라는 안내 + 파일 이름"]
    ]
  }
}
```
