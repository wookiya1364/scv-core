# TESTS — scv/routines/ 루틴 레이어

## Test scenarios

1. **규약 시딩** — 새 hydrate 에 `scv/routines/README.md` 가 생성되고 루틴
   frontmatter 스키마(name/cadence/guardrails/exit/report)가 문서화돼 있다.
2. **routine --list** — 루틴 md 2개를 만든 프로젝트에서 `action:routine
   --list` 가 이름·주기를 표로 출력하고, 루틴이 없으면 안내 문구를 낸다.
3. **routine 실행 계약** — `action:routine <name>` 프로토콜이 (a) 해당 md 의
   과업·가드레일·종료 조건을 읽고, (b) permanent 브랜치 직접 쓰기를
   금지하며, (c) report 형식 요약과 (d) 호스트별 스케줄 등록 예시를
   출력하도록 지시한다 (run-dry 프로토콜 assert).
4. **존재하지 않는 루틴** — `action:routine nope` → 명확한 에러 + 사용 가능
   목록 (exit 1).
5. **내장 템플릿 4종** — regression-runner / outdated-verifier /
   promote-staleness / archive-integrity 템플릿이 존재하고, 각각 frontmatter
   스키마를 통과한다 (frontmatter lint).
6. **outdated-verifier 연동** — stale 문서에 OUTDATED-CANDIDATE 가 있는
   픽스처에서 해당 루틴 템플릿의 지시가 readpath outdated 출력을 입력으로
   삼는 것을 확인 (스크립트 신호 연동 assert).
7. **액션 계약 15개** — actions.json 에 `routine` 이 추가되고 계약 테스트가
   "15개 액션 정확히 1회"로 갱신되어 통과한다.
8. **스케줄링 비소유** — routine 스크립트/프로토콜 어디에도 cron 등록·데몬
   실행 코드가 없다 (grep 검증) — 안내 텍스트만 존재.

## How to run

```bash
bash core/tests/run-dry.sh
for t in core/tests/test-*.sh; do bash "$t"; done
bash tests/run.sh
```

## Pass criteria

- 시나리오 8건 커버·통과, 기존 스위트 무회귀
- wrapper handoff 2건 발행 (routines 등록 계약 포함)
