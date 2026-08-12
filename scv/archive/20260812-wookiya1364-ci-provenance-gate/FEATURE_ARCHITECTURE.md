---
title: 계획 없는 구현 PR 을 CI 가 막는다 (프로버넌스 게이트)
slug: 20260812-wookiya1364-ci-provenance-gate
created_at: 2026-08-12
status: planned
---

# Architecture — 계획 없는 구현 PR 을 CI 가 막는다 (프로버넌스 게이트)

> 이 계획의 구성 요소 흐름. **`/scv:work` 전에 검토하고 고칠 것** —
> 다이어그램은 LLM 이 생성한 것이라 부정확할 수 있다.

## 1. Component data flow

PR 하나가 게이트를 통과하는 경로. 노란색은 이 계획이 새로 만드는 것이다.
면제 네 갈래는 모두 통과로 빠지고, 남은 PR 만 본 검사와 스키마 검사를 받는다.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#1e1e1e','primaryTextColor':'#fff','primaryBorderColor':'#9096a8','lineColor':'#e7e9f0','secondaryColor':'#2d2d2d','tertiaryColor':'#1e1e1e','background':'#171922','edgeLabelBackground':'#171922'}}}%%
flowchart TB
  PR[pull_request 이벤트] -->|"BASE_REF, HEAD_REF, PR_TITLE"| BranchFlow[branch-flow.yml 의 기존 잡]
  BranchFlow -->|"git diff --name-status merge-base...HEAD"| Gate[check-provenance.sh]:::new

  Gate -->|"BASE_REF 가 stage 또는 main"| Pass1[통과 · 릴리스 체인 면제]
  Gate -->|"HEAD_REF 가 chore/core-*"| Pass2[통과 · 봇 동기화 면제]
  Gate -->|"PR_TITLE 에 [no-plan: 이유]"| Pass3["통과 · 명시적 예외"]
  Gate -->|"변경이 전부 scv/** 또는 *.md"| Pass4["통과 · 코드 변경 없음"]

  Gate -->|"--diff-filter=A 로 추가된 계획 찾기"| Added{"추가된<br/>scv/archive/*/PLAN.md"}
  Added -->|"하나도 없음"| Fail1["실패 · /scv:work 또는 no-plan 예외 안내"]
  Added -->|"한 개 이상, --plan 진입점은 신규"| Schema["check-frontmatter.sh"]

  Schema -->|"yaml_has_key, yaml_get, yaml_get_list"| YamlLib["lib/yaml.sh"]
  Schema -->|"필수 키 누락 또는 잘못된 status/kind"| Fail2["실패 · 위반 항목 출력"]
  Schema -->|"PLAN 스키마 통과"| Pass5["통과"]

  classDef new fill:#FFE082,stroke:#F57C00,stroke-width:2px,color:#000
```

`lib/yaml.sh` 는 새로 만들지 않고 그대로 쓴다 — `yaml_get_list` 가 인라인
flow(`raw_sources: []`) 와 block 두 형식을 이미 처리하고, 실제 아카이브된 계획
8 개 중 7 개가 flow 형식이다.

## 2. Position in whole architecture

> Skipped — no graphify graph available.
> Run `/graphify` and re-run `/scv:promote` on this folder to generate diagram 2.
