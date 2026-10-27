---
title: 코어 · 래퍼 · 모드 문서 최신화 — 빠진 기능 채우기 + 루프 · 구조 · 미러 그림
slug: 20261027-wookiya1364-docs-refresh-diagrams
created_at: 2026-10-27
status: planned
---

# Architecture — 코어 · 래퍼 · 모드 문서 최신화

> 이 작업을 두 장의 그림으로 본다. **`/scv:work` 전에 검토하고 고쳐라** — 그림은 모델이 그렸으므로 틀린 곳이 있을 수 있다.

## 1. Component data flow

문서 검사가 기능 목록과 네 저장소의 문서를 대조하는 순서. 같은 기능 목록을 README 의 '기능 한눈에' 표도 쓴다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Actions[(core/actions.json<br>명령 20개)]
  Docs[(문서 원문<br>코어 · claude · codex · 모드)]
  readSources["① readSources<br>파일 읽기"]
  listFeatures["② listFeatures<br>기능 목록"]
  findMentions["③ findMentions<br>기능 × 문서 표"]
  findGaps["④ findGaps<br>빠진 칸"]
  checkDiagrams["⑤ checkDiagrams<br>루프 · 구조 · 미러 그림"]
  formatReport["⑥ formatReport<br>줄 + 종료 코드"]
  printReport["⑦ printReport<br>화면 출력"]

  Actions -->|"jq '.actions[].id'"| readSources
  Docs -->|"README.{md,ko,ja} · docs/architecture.md"| readSources
  readSources -->|"원문 묶음"| listFeatures
  listFeatures -->|"기능 · 찾을 말"| findMentions
  readSources -->|"문서 원문"| findMentions
  findMentions -->|"있음/없음 표"| findGaps
  readSources -->|"문서 원문"| checkDiagrams
  findGaps -->|"빠진 기능 · 파일"| formatReport
  checkDiagrams -->|"빠진 그림"| formatReport
  formatReport -->|"출력 줄 · exit"| printReport

  classDef key fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
  class findGaps,checkDiagrams key
```

## 2. Position in whole architecture

이 작업이 닿는 곳. 새로 생기는 것은 노란색, 새 연결은 점선.

> Source: scv graph (built 2026-10-27)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph "."
    README[README.md · ko · ja]
    CHANGELOG[CHANGELOG.md]
  end
  subgraph "docs"
    Arch[docs/architecture.md]
    WI[docs/wrapper-integration.md]
  end
  subgraph "core/tests"
    RunDry[core/tests/run-dry.sh]
    DocsCov[test-docs-coverage.sh]:::new
  end
  subgraph "../scv-claude-code"
    CCReadme[README 3개 언어]
    Demo[demo/ Remotion<br>TheLoop · Architecture]
    MirrorComp[Mirror 컴포지션]:::new
  end
  subgraph "../scv-codex"
    CXReadme[README 3개 언어]
  end
  subgraph "scv-mods"
    ModsReadme[README.md<br>미러 쓰는 법]:::new
  end

  README -->|"×1 · skills-layout-gates"| CHANGELOG
  README -->|"×1 · skills-layout-gates"| WI
  Arch -->|"×1 · process-metrics"| RunDry
  DocsCov -.->|"기능 목록 대조"| README
  DocsCov -.->|"기능 목록 대조"| Arch
  DocsCov -.->|"--wrappers"| CCReadme
  DocsCov -.->|"--wrappers"| CXReadme
  DocsCov -.->|"--mods"| ModsReadme
  Demo -.->|"render-gif → the-loop · architecture"| CCReadme
  MirrorComp -.->|"render-gif → mirror.gif"| ModsReadme
  RunDry -.->|"새 검사 포함"| DocsCov

  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 3. Screen mockups

### 미러 쓰는 법 (모드 README 에 실을 순서)

```screen
{
  "title": "미러 쓰는 법 — 두 컴퓨터",
  "diagram": [
    { "label": "순서", "code": "sequenceDiagram\n  autonumber\n  participant A as ① 일하는 세션 (컴퓨터 A)\n  participant B as ② 보는 세션 (컴퓨터 B, 그 앱에서 직접 연 세션)\n  A->>A: /scv-dashboard — 주소 출력\n  B->>A: /scv-mirror <주소> — 거울 요청\n  A-->>B: 상태를 보냄 (두 모델은 읽지 않음)\n  Note over B: SCV 칸에 A 의 진행이 보임\n  alt 같은 세션에서 침\n    A-->>A: 자기 자신이라 보낼 곳 없음\n  end\n  B->>B: /scv-mirror stop — 거울 끔" }
  ],
  "functions": [
    { "marker": "1", "title": "일하는 세션", "notes": ["/scv-dashboard 가 이 세션의 주소를 알려 준다", "Remote Control 이 켜져 있으면 그 id 가 주소"] },
    { "marker": "2", "title": "보는 세션", "notes": ["다른 컴퓨터의 데스크톱 앱에서 직접 연 세션이어야 한다", "Remote Control 뷰어(claude.ai · 폰 · 다른 컴퓨터 앱의 원격 보기)는 칸을 그리지 못한다"] }
  ],
  "validations": {
    "title": "주의",
    "columns": ["번호", "조건", "결과"],
    "rows": [
      ["1", "일하는 세션 자신에서 /scv-mirror 를 침", "자기 자신이라 보낼 곳 없음 오류"],
      ["1, 2", "어느 한쪽이 scv-dashboard 0.2.0 미만", "거울이 안 됨 — 둘 다 0.2.0 이상 필요"]
    ]
  }
}
```
