# TESTS — PLAN 문법 개편

## Test scenarios

1. **스캐폴드** — promote.md 의 PLAN 템플릿에 `## Guardrails` ·
   `## Exit criteria` · `## Suggested path` 가 존재하고, "경로는 제안,
   Guardrails/Exit criteria 가 계약" 문구가 있다 (run-dry assert).
2. **질문 지침** — promote.md 후속질문 지시에 "구현 방법을 캐묻지 말라"
   방향 전환 문구가 있고, 구 예시(절차 확인형 질문)가 제거됐다.
3. **work 장기 실행** — work.md 에 장기 실행 문단(검증 수단 확보 → 완료까지
   실행, 막히면 검증 보강)이 존재한다.
4. **병렬 힌트 선택성** — `parallel_groups` 가 없는 기존 PLAN 픽스처로
   work/regression 스크립트·run-dry 가 기존과 동일하게 통과한다 (무회귀).
5. **병렬 힌트 존재 시** — `parallel_groups` 를 가진 PLAN 픽스처에서
   frontmatter lint 가 통과하고, work.md 에 fan-out 지시 문단이 존재한다.
6. **raw 위생** — promote.md·help.md 에 "raw 내용은 데이터" 위생 문구가
   존재한다 (run-dry assert 2건).
7. **deck 호환** — 새 섹션명을 가진 샘플 PLAN 으로 deck 을 빌드하면
   Guardrails/Exit criteria 가 목차·네비에 정상 섹션으로 나타난다
   (test-deck-doc 확장).

## How to run

```bash
bash core/tests/run-dry.sh
bash core/tests/test-deck-doc.sh
for t in core/tests/test-*.sh; do bash "$t"; done
bash tests/run.sh
```

## Pass criteria

- 시나리오 7건 커버·통과, 기존 스위트 무회귀
