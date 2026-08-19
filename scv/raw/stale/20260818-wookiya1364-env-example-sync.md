# .env.example.scv 자동 최신화 — root 불가침의 명명된 예외

2026-08-18, effort governor(0.29.0) 문서화 감사에서 발견된 전파 공백의 해결 방향을
대화로 결정한 기록.

## 발견된 문제

`/scv:sync` 는 "SCV owns only `scv/`; root is user-owned and never touched" 원칙으로
`template/scv/*.md` 만 동기화한다. `.env.example.scv` 는 hydrate 가 프로젝트 루트에
심는 파일이라 sync 의 손이 닿지 않는다. 그 결과:

- 0.29.0 이전에 hydrate 된 기존 프로젝트는 SCV_EFFORT_MODE 같은 새 `.env` 옵션의
  문서 블록을 영영 받지 못한다.
- 동작은 무해하다 (unset = auto). 그러나 사용자가 `ask`/`off` 모드의 존재 자체를
  파일에서 발견할 수 없다. 앞으로 `.env` 옵션이 추가될 때마다 같은 공백이 반복된다.
- 0.28.0 의 "refresh templates on action start"(autosync) 도 sync 를 경유하므로
  같은 경계에 막힌다.

## 결정된 방향 (사용자)

**무조건 최신으로 덮어쓰기 + 기존 프로젝트 강제 마이그레이션.** 별도 마이그레이션
명령 없이, sync 대상에 이 파일을 넣고 autosync 가 액션 시작 시 전파한다.

근거:
- 이 파일은 예시 파일이다. 실제 설정은 `.env` 에 살고, sync 는 `.env` 를 절대
  건드리지 않는다. 사용자 데이터 손실 표면이 원래 작다.
- 0.28.0 의 HEAD 대조 장치와 정확히 맞물린다: git 이 복원 못 하는 내용은 DIRTY 로
  거부(--force 만 오버라이드), 커밋된 커스텀은 git 이력으로 복구. "백업 디렉토리
  없이 git 이력이 유일한 답"이라는 기존 결정과 일관된다.

## 대화에서 확정한 경계 (소크라테스식 명확화)

1. **파일 부재 시 재생성.** 사용자가 지웠든 오래된 hydrate 라 애초에 없든, 없으면
   최신 템플릿으로 새로 내려놓는다. "무조건 최신" 결정과 일관되고, 삭제로 예외를
   회피하는 경로도 닫는다.
2. **scv/ 심볼링크 시 같이 건너뛴다.** 템플릿 패스 전체가 하나의 단위로 유지된다.
   기존 "심볼링크면 WARN 하나로 전체 스킵" 규칙에 예외를 만들지 않는다.
3. **DIRTY 거부 시 해결될 때까지 재시도.** 기존 스탬프 규칙 그대로 — 거부가 있으면
   TEMPLATE_VERSION 스탬프를 올리지 않고 PARTIAL 보고, 다음 액션마다 재시도.
   낡은 파일이 조용히 방치되는 false-convergence 를 막는 0.28.0 설계와 일관.

## 불변 조건 (invariants)

- `.env` 자체는 절대 불가침 — sync 는 어떤 경우에도 읽기만 하고 쓰지 않는다.
- HEAD 복원 불가 내용은 DIRTY 거부 — `--force` 만 오버라이드.
- root 의 다른 파일은 계속 불가침 — 예외는 `.env.example.scv` 단 하나.
- 미채택·pre-2.x 프로젝트는 autosync 가 손대지 않음 — 기존 게이트 유지.

## 관련 파일

- core/scripts/sync.sh (템플릿 패스, HEAD 대조·DIRTY 거부 장치)
- core/scripts/hydrate.sh:89 (dotglob 로 .env.example.scv 를 루트에 심는 지점)
- core/scripts/lib/scvroot.sh (scv_autosync — 액션 시작 시 전파 게이트)
- core/tests/test-sync-dirty*.sh (기존 더티 거부 스위트)
- TEMPLATE_VERSION (스탬프 게이트)
