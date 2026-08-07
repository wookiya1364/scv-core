# TESTS — adoption 단일화 + 표준 문서 7종 제거

## Test scenarios

1. **hydrate 산출 축소** — 새 hydrate 결과에 7종(DOMAIN/ARCHITECTURE/DESIGN/
   AGENTS/TESTING/INTAKE/RALPH_PROMPT)이 존재하지 않고, 유지 파일(SCV.md,
   PROMOTE.md, REPORTING.md, raw/README.md, WORKSPACE.yaml.example)은 기존과
   동일하게 생성된다.
2. **--new 거부** — `hydrate.sh init . --new` → exit 1 + 마이그레이션 안내,
   파일 0개 생성 (fail-closed).
3. **sync 삭제 전파** — 구버전으로 hydrate 된 프로젝트(7종 존재, 일부에
   사용자 내용 추가)에서 sync 실행 → 7종 전부 삭제되고, 각 파일이
   `.scv-backup/` 에 원본 그대로 존재하며, CHANGES 에 `DELETED ... (backed
   up)` 7건이 보고된다.
4. **백업 실패 시 중단** — 백업 디렉터리를 쓰기 불가로 만든 상태에서 sync →
   삭제가 한 건도 일어나지 않고 명확한 에러로 중단 (fail-closed).
5. **dry-run** — `sync --dry-run` 은 삭제 예정 7건을 표시만 하고 파일·백업
   모두 무변경.
6. **유지 파일 불변** — 시나리오 3 이후 SCV.md(PROJECT:LOCAL 포함)·
   PROMOTE.md·REPORTING.md 내용이 삭제·손상되지 않는다.
7. **참조 잔존 0건** — `grep -rE "INTAKE|DOMAIN\.md|ARCHITECTURE\.md|DESIGN\.md|AGENTS\.md|TESTING\.md|RALPH_PROMPT"`
   가 core 스크립트·프로토콜·템플릿에서 CHANGELOG/릴리스 노트 외 0건
   (마이그레이션 에러 메시지 등 의도된 잔존은 명시 목록으로 허용).
8. **draft 게이트 소멸** — help/status 출력에 draft/INTAKE 게이트 관련
   문구가 더 이상 나타나지 않는다 (run-dry assert).

## How to run

```bash
bash core/tests/run-dry.sh
for t in core/tests/test-*.sh; do bash "$t"; done
bash tests/run.sh
```

## Pass criteria

- 시나리오 8건 전부 자동 테스트/run-dry assert 로 커버되고 통과
- 기존 스위트 무회귀 · TEMPLATE_VERSION 2.0.0 · CHANGELOG 에 breaking 명시
