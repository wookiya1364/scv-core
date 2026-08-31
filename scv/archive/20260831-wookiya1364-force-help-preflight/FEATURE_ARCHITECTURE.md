---
title: "강제를 preflight 로 — 진단은 주입하고 되돌림은 없앤다"
slug: 20260831-wookiya1364-force-help-preflight
created_at: 2026-08-31
status: planned
---

# Architecture — 강제를 preflight 로

> 바뀌는 것은 **강제 지점의 위치** 하나다. 턴의 끝에서 시작으로 옮기면 반복할
> 일 자체가 없어진다.

## 1. Component data flow

지금과 바뀐 뒤를 나란히 둔다. 위가 지금, 아래가 바뀐 뒤다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  subgraph NOW["지금 (0.39.0) — 끝에서 되돌린다"]
    N1["프롬프트 훅"] -->|"안내 문구만"| N2["모델이 본문을 다 쓴다"]
    N2 --> N3["종료 훅"]
    N3 -->|"영수증 없음 → 차단"| N2
    N3 -->|"영수증 있음"| N4["턴 종료"]
  end

  subgraph NEW["바뀐 뒤 — 시작에서 채운다"]
    P1["프롬프트 훅"] -->|"진단 + 분류 지침 + 표시줄"| P2["모델이 본문을 한 번 쓴다"]
    P2 --> P3["종료 훅"]
    P3 -->|"되돌리지 않는다"| P4["턴 종료"]
  end

  N3:::bad
  P1:::good
  classDef bad fill:#5a2222,stroke:#f4556d,stroke-width:2px,color:#fff
  classDef good fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 2. Position in whole architecture

이 변경이 시스템 어디에 앉는지. 새로 생기는 것은 노란색, 없어지는 것은 붉은색이다.

> Source: graphify graph (built 2026-08-26).

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph C10["Codex Guard Receipts"]
    R1["영수증 — 위조 불가 증거"]
    R2["스킬 호출 발급 경로"]
  end
  subgraph C6["항상-라우팅 묶음"]
    A1["항상 라우팅 스위치"]
    A2["프롬프트 훅 stdout — 매 턴 모델 컨텍스트"]
    A3["한계 — 지시 주입일 뿐 코드 레벨 차단 아님"]
  end
  subgraph C0["Settings Propagation & Lint"]
    S1["설정 파일"]
  end

  X1["되돌림 판정 (종료 훅)"]:::gone
  X2["턴 상태 저장소"]:::gone
  X3["가드의 라이브러리 의존"]:::gone
  N1["진단 주입 (preflight)"]:::new
  N2["분류 지침 세 갈래"]:::new

  A1 --> A2
  A2 --> A3
  R1 --> R2

  N1 -.->|"A3 의 한계를 인정하고 목적을 바꾼다"| A3
  N1 -.->|"같은 통로로 실린다"| A2
  N2 -.->|"세 갈래를 모두 정당하게 둔다"| N1
  X1 -.->|"판정 근거가 없어 삭제"| R1
  X3 -.->|"두 번째 소비자가 사라져 원복"| R2
  N1 -.->|"스위치 뜻이 바뀐다"| S1

  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
  classDef gone fill:#5a2222,stroke:#f4556d,stroke-width:2px,color:#fff
```

## 3. Screen mockups

화면이 없는 변경이라 큰 그림 자리는 순서도가 대신한다. 번호는 그림과 아래 설명이
같은 것을 가리킨다.

### 한 턴에 무슨 일이 일어나는가

```screen
{
  "title": "preflight 로 바뀐 한 턴",
  "pageCode": "SCV-HOOK-PRE-01",
  "autoMarkers": false,
  "diagram": [
    { "label": "순서",
      "code": "sequenceDiagram\n  autonumber\n  participant H as 호스트\n  participant P as ① 프롬프트 훅\n  participant M as 모델\n  participant S as ② 종료 훅\n  H->>P: 사용자 메시지\n  P->>P: ③ 상태 점검 실행\n  P-->>H: 진단 + 분류 지침 + 표시줄\n  alt 앞을 보는 턴\n    M->>M: 대화 모드 호출\n  else 뒤를 보는 턴\n    M->>M: 아카이브 검색 호출\n  else 둘 다 아님\n    M->>M: 주입된 진단만 보고 답한다\n  end\n  M-->>H: 본문 (한 번)\n  H->>S: 응답 종료\n  S-->>H: 통과 — 되돌리지 않는다" }
  ],
  "functions": [
    { "marker": "1", "title": "프롬프트 훅", "step": "readSwitches → emitLines",
      "notes": ["턴 시작에 진단·지침·표시줄을 싣는다. 이것이 preflight 다."] },
    { "marker": "2", "title": "종료 훅", "step": "(없음)",
      "notes": ["강제 블록이 삭제된다. 저널 기록만 남는다."] },
    { "marker": "3", "title": "상태 점검", "step": "runProbe → trimToDiagnosis",
      "notes": ["전체 5,898바이트 중 진단 3,148바이트만 싣는다. 실측 0.45초."] }
  ],
  "validations": {
    "title": "전후 비교",
    "columns": ["항목", "지금 (0.39.0)", "바뀐 뒤"],
    "rows": [
      ["본문 생성", "되돌린 횟수만큼 반복", "항상 한 번"],
      ["강제 지점", "턴의 끝", "턴의 시작"],
      ["매 턴 주입", "안내 문구만", "진단 + 분류 지침"],
      ["앞도 뒤도 아닌 턴", "그래도 되돌림", "그냥 답한다"],
      ["가드", "라이브러리를 읽음", "다시 홀로 선다"],
      ["표시줄", "있음", "있음 (유지)"]
    ]
  }
}
```
