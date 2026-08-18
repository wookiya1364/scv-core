# Test Plan — effort governor

## Overview

세 층을 검증한다: 판정 스크립트의 결정성(같은 입력 = 같은 밴드, 아카이브 14건
재현), 모드 계약(auto/ask/off 의 상호 배타성과 off 의 완전 무동작), 프로토콜
집행 텍스트의 정합(격자·승급·기록이 명문화되고 guidance 계약을 깨지 않음).
판정이 확률적이라는 오해를 막는 것이 핵심이다 — 스크립트는 결정적이고, 확률은
규칙이 미래 계획에 맞을지에만 붙는다.

## Test scenarios

### T1. 세 밴드가 규칙 순서대로 판정된다

- **Setup**: 픽스처 계획 3벌 — (a) frontmatter `parallel_groups` 선언,
  (b) 본문에 래퍼 후속 선언, (c) 둘 다 없음
- **Run**: `effort-class.sh <dir>`
- **Expected**: (a) orchestration, (b) heavy, (c) standard. R1 이 R2 보다
  우선한다: (a)+(b) 동시 선언 픽스처는 orchestration
- **Pass criterion**: `EFFORT_CLASS:` 라인이 정확히 일치, `EFFORT_REASON:` 이
  발화한 규칙을 이름 붙인다

### T2. 승급 장전 힌트가 2-of-3 에서만 켜진다

- **Setup**: {cross-repo, adversarial 요구, raw≥9000B} 를 0·1·2·3개 조합한 픽스처
- **Expected**: 0~1개 → `EFFORT_ESCALATION: normal`, 2~3개 → `armed`
- **Pass criterion**: 네 경우 전부 일치

### T3. frontmatter 선언이 항상 이긴다

- **Setup**: 신호는 standard 인데 `effort_class: orchestration` 선언, 역방향도
- **Expected**: 선언 값 그대로, REASON 에 declared 표기
- **Pass criterion**: 두 방향 모두 선언 승

### T4. 아카이브 14건이 백테스트 예측을 재현한다

- **Setup**: 이 저장소의 실제 `scv/archive/` 14개 슬러그 (이 계획 이전 것들)
- **Run**: 각 폴더에 effort-class.sh
- **Expected**: 백테스트가 낸 예측과 동일 — orchestration 0건(당시 계획들에
  parallel_groups 없음), heavy = 래퍼 후속 선언 슬러그들, 나머지 standard.
  sync-autopilot 는 heavy 로 나오되 `armed` 다 (2-of-3 충족 — 그 미스를 사다리가
  받는다는 설계의 재현)
- **Pass criterion**: 14건 전부 기대 밴드, sync-autopilot 만 armed 검증 필수

### T5. 판정은 결정적이고 무해하다

- **Setup**: 같은 픽스처에 3회 연속 실행 + 실행 전후 트리 해시
- **Expected**: 세 번 같은 출력, 파일 변경 0
- **Pass criterion**: 출력 diff 없음, `find -newer` 결과 없음

### T6. off 모드는 완전 무동작이다

- **Setup**: 프로토콜 텍스트 검사 — work.md·codegen.md 의 governor 절
- **Expected**: off 분기가 "판정 스크립트를 호출하지 않는다" 를 명시하고,
  auto/ask/off 세 분기가 상호 배타로 서술된다. 승급 사다리는 모드 무관 절에
  있다(off 에서도 품질 보호는 동작 — 단 판정이 없으므로 세션 그대로 시작)
- **Pass criterion**: 세 분기 각 1회 존재, off 분기에 무호출 명시

### T7. 격자와 사다리가 명문화된다

- **Expected**: 두 프로토콜에 밴드×단계 격자(기계=최저, 종합=경량, 구현·검증=
  밴드 의존), 승급 트리거(동일 단계 적색 2회·반박 복수), 강등 금지, 아카이브
  --reason 실측 기록 지시가 있다. 호스트 레벨명은 등장하지 않는다
- **Pass criterion**: 각 요소 grep 존재 + 레벨명 부재

### T8. 문서·계약 정합

- **Run**: `tests/test-guard-consistency.sh`, `guidance-filter.sh --lint` (두
  프로토콜), full 투영 cmp, `tests/test-host-neutral.sh`
- **Expected**: 전부 통과 — governor 절이 마커 균형·투영 동일성·구문 스윕·호스트
  중립을 깨지 않는다
- **Pass criterion**: 4개 검사 초록

### T9. 회귀 증명 — 옛 코드에서 실패한다

- **Setup**: effort-class.sh 를 제거한 사본 payload + governor 절 없는 HEAD
  프로토콜
- **Expected**: T1·T6 급 케이스가 옛 상태에서 실패한다
- **Pass criterion**: 사본에서 실패 수 > 0, 현행에서 0

## How to run

```bash
bash core/tests/test-effort-class.sh
```

## Pass criteria

- T1–T9 전부 통과, 특히 T4(백테스트 재현)와 T9(회귀 증명)
- 전체 스위트(tests/run.sh · run-dry · core/tests · host-neutral ·
  guard-consistency) 실패 0
- 릴리스 아티팩트에 effort-class.sh 포함

## Related Documents

- [`PLAN.md`](./PLAN.md)
