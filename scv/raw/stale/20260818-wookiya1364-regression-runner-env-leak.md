# 회귀 러너의 autosync 가드 누수 — 시나리오는 깨끗한 환경에서 돈다

2026-08-18, env-example-autorefresh 아카이브 직전 누적 회귀에서 발견된 러너 결함의
트리아지 기록. 사용자 결정: regression (러너 수정 후속 플랜).

## 발견된 문제

`regression.sh`(payload `scripts/regression.sh`)는 시작할 때 `scv_init_paths`를
호출한다. 그 안의 `scv_autosync`는 프로세스 트리 재진입 방지를 위해
`export SCV_AUTOSYNC_RUNNING=1`을 **버전 비교보다 먼저** 실행한다
(`core/scripts/lib/scvroot.sh`). export된 값은 러너가 각 슬러그의 `## How to run`을
실행할 때 자식 프로세스로 그대로 상속된다.

결과: autosync 훅 자체를 검증하는 계약이 러너 안에서만 죽는다.
`scv_autosync`는 `SCV_AUTOSYNC_RUNNING`이 설정돼 있으면 즉시 return하므로,
훅의 모든 동작(새로고침·경고·PARTIAL 보고)이 무동작이 된다.

## 실측 증거 (2026-08-18)

- 누적 회귀: 11개 슬러그 중 `20260818-wookiya1364-sync-autopilot` 1개 실패
  (How to run = test-guard.sh && test-autosync.sh && test-sync-dirty.sh 체인,
  test-autosync 구간 10 passed / 11 failed).
- 오염 환경 주입: `SCV_AUTOSYNC_RUNNING=1 bash core/tests/test-autosync.sh`
  → 10/11 — 러너 안 실패와 정확히 동일 재현.
- 깨끗한 환경: `bash core/tests/test-autosync.sh` → 21/21.
- 근거 기록: scv/DECISIONS.md 2026-08-18 env-example-autorefresh archived 항목.

## 결정된 수정 방향 (사용자)

**러너만 수정한다.** 러너가 시나리오를 실행할 때, 자기가 켠 내부 플래그
`SCV_AUTOSYNC_RUNNING`을 환경에서 지우고(`env -u` 상당) 실행한다.
test-autosync.sh의 call() 헬퍼 등 스위트 쪽 방어 보강은 하지 않는다 —
스위트가 호출자의 누수를 가려버리면 다른 곳의 같은 버그를 뒤늦게 발견하게
된다는 이유로 기각. 대신 이 맹점(미래의 다른 호출자가 같은 플래그를 켠 채
스위트를 부르면 같은 오판 재발)은 Risk로 기록한다.

## 불변 조건 (invariants, 대화로 확정)

1. 러너 자신의 재진입 방지는 유지 — 한 번의 러너 실행 안에서 헬퍼들이
   autosync 체크를 중복하지 않는 본래 목적은 그대로 살아 있어야 한다.
   (비유: 건물 입구의 소독 완료 스티커는 유지, 방문객 이마에 붙이는 것만 중단)
2. 아카이브된 TESTS 본문 무수정 — 잘못은 러너에 있으니 러너만 고친다.
3. 사용자가 직접 설정한 환경변수는 통과 — SCV_AUTOSYNC=off 같은 사용자 의도의
   env는 시나리오에 그대로 전달된다. 제거 대상은 러너가 스스로 export한 내부
   플래그뿐.
4. 러너의 다른 계약 불변 — --ci 비대화, supersede/obsolete 스킵 그래프,
   성공·실패 판정 규칙은 손대지 않는다.

## 관련 파일

- core/scripts/regression.sh (시나리오 실행 지점 — 수정 대상)
- core/scripts/lib/scvroot.sh (scv_autosync의 export 지점 — 수정하지 않음, 참조만)
- core/tests/test-autosync.sh (call 헬퍼 — 수정하지 않음)
- scv/archive/20260818-wookiya1364-sync-autopilot/ (러너 안에서만 붉던 계약 —
  수정 후 러너 안 통과가 Exit criteria)
