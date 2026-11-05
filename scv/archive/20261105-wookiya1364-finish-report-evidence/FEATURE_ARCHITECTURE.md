---
title: 끝 보고 세 줄 + 근거 목록 — 비판적 사고 첫 판
slug: 20261105-wookiya1364-finish-report-evidence
created_at: 2026-11-05
status: planned
---

# Architecture — 끝 보고 세 줄 + 근거 목록

> 이 기능의 그림 두 장과 끝 보고 견본 한 장. **`/scv:work` 전에 검토 · 수정** — 그림은 모델이 그려 틀린 곳이 있을 수 있다.

## 1. Component data flow

종료 훅이 원본을 읽어 근거 목록을 만들고, 끝 답의 세 줄과 대조해 빠진 것이 있으면 기존 묶음 막기에 이유 하나로 더한다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart LR
  Transcript[(호스트 원본)]
  LedgerFile[(근거 목록 파일 · 비공개 기록)]
  PromptHook[매 턴 훅]
  StopHook[종료 훅]
  subgraph pure["순수 단계"]
    TurnGroup[scv_turn_group 턴 묶기]
    Evidence[scv_evidence_build 근거 목록]
    TestFirst[scv_evidence_test_first 실패 먼저]
    Needed[scv_finish_needed]
    Scan[scv_finish_scan]
    Check[scv_finish_check 대조]
    Note[scv_finish_note 교정 문구]
    RuleLine[scv_finish_rule_line 안내 한 줄]
  end
  Gates[묶음 막기 scv_gates_reason]
  StopHook -->|"원본 끝 줄 읽기(입구)"| Transcript
  StopHook -->|"scv_turn_group(원본 줄들)"| TurnGroup
  TurnGroup -->|"이번 턴 사건 줄들(입력 모양으로 종류)"| Evidence
  Evidence -->|"근거 목록"| TestFirst
  Evidence -->|"근거 목록"| Needed
  StopHook -->|"scv_finish_scan(끝 답, 언어)"| Scan
  Scan -->|"줄 내용"| Check
  Needed -->|"none · short · full"| Check
  TestFirst -->|"못 본 시험 이름들"| Check
  Evidence -->|"근거 목록"| Check
  Check -->|"빠진 것 목록"| Note
  Note -->|"이유 한 줄"| Gates
  Gates -->|"decision: block — 한 턴에 한 번"| StopHook
  StopHook -->|"가림 필터 → 쓰기(출구)"| LedgerFile
  PromptHook -->|"scv_finish_rule_line(언어)"| RuleLine
```

## 2. Position in whole architecture

SCV 안에서 이 기능이 끼는 자리. 새 부분은 노란색.

> Source: scv graph (built 2026-11-05)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  subgraph tmpl["core/template"]
    OnStop[on-stop.sh 종료 훅]
    OnPrompt[on-user-prompt.sh 매 턴 훅]
    SCVmd[scv/SCV.md 최상위 규칙]
  end
  subgraph scripts["core/scripts"]
    HelpState[lib/help-state.sh]
    MPLib[lib/model-prompting.sh]
    Journal[journal-append.sh 가림 필터]
    FinishLib[새 순수 단계 scv_finish_* · scv_evidence_*]:::new
  end
  subgraph contracts["core/contracts"]
    Writing[writing.md 글 모양]
    FinishContract[finish-report.md 새 계약]:::new
  end
  subgraph protocols["core/protocols"]
    HelpMd[help.md 잠긴 답 모양 절]
  end
  OnStop -->|"함께 바뀜 ×6 · forced-help-invocation"| OnPrompt
  HelpState -->|"함께 바뀜 ×5 · answer-lint-turn-race"| OnStop
  MPLib -->|"함께 바뀜 ×5 · per-model-prompting"| OnStop
  OnStop -.->|"이유 하나 더함"| FinishLib
  OnPrompt -.->|"안내 한 줄"| FinishLib
  OnStop -.->|"근거 목록 쓰기"| Journal
  SCVmd -.->|"5조가 가리킴"| FinishContract
  FinishContract -.->|"관계 선언(같은 요구 두 번 안 씀)"| Writing
  FinishContract -.->|"관계 선언(절은 그대로)"| HelpMd
  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

## 3. Screen mockups

### 끝 보고 — 일한 턴

```screen
{
  "title": "끝 보고 — 일한 턴",
  "autoMarkers": false,
  "body": [
    { "type": "text", "value": "> 다시 쓴 요청: …" },
    { "type": "header", "title": "결과를 말하는 굵은 주제", "subtitle": "결과 · 풀이 불릿들" },
    { "type": "card", "title": "확인 범위", "marker": "1", "body": [
      { "type": "list", "items": [
        { "label": "확인한 것: 언어 시험 실행 → 14개 통과" },
        { "label": "확인 못 한 것: 실제 세션에서 고쳐 쓰는지는 아직 못 봄" },
        { "label": "제가 대신 정한 것: 걸린 줄은 하나, 60바이트에서 자름" }
      ] }
    ] }
  ],
  "functions": [
    { "marker": "1", "title": "확인 범위 세 줄", "step": "scv_finish_scan",
      "notes": ["도구를 쓴 모든 턴의 끝 보고에 붙음", "'확인한 것'은 근거 목록 항목의 쉬운 이름으로 짚음", "'없음'은 이유가 있어야 인정"] }
  ],
  "states": [
    { "marker": "1", "label": "짧은 턴(SCV 기록 · 질문만)", "body": [
      { "type": "text", "value": "확인 범위: 기록만 함 — 확인 · 결정 없음" }
    ] }
  ],
  "validations": [
    { "marker": "1", "when": "턴 끝(종료 훅)", "condition": "세 줄(짧은 턴은 한 줄) 중 빠진 것", "message": "빠진 줄 이름을 짚는 교정 문구", "shownAs": "한 턴에 한 번 막고 고친 부분만 덧붙임" },
    { "marker": "1", "when": "턴 끝(종료 훅)", "condition": "'없음'에 이유가 없음", "message": "이유를 붙이라는 교정 문구", "shownAs": "같은 막기에 묶임" },
    { "marker": "1", "when": "턴 끝(종료 훅)", "condition": "'확인한 것'이 근거 목록에 없는 실행을 짚음", "message": "짚은 이름을 들어 근거가 없다고 알림", "shownAs": "같은 막기에 묶임" },
    { "marker": "1", "when": "턴 끝(종료 훅)", "condition": "바꾼 시험의 실패를 못 봤는데 안 밝힘", "message": "그 시험 이름을 '확인 못 한 것'에 적으라고 알림", "shownAs": "같은 막기에 묶임" }
  ]
}
```
