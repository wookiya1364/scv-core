# PR·Slack 영상은 이번 기능(슬러그) 것만 — 기본값 (0.32.0 후보)

## 사용자 요청 (2026-08-21, wookiya1364)

> scv에서 slack 알람줄때 PR올려주면서 비디오도 같이 보내주잖아. 그거 비디오가 내가
> 이번에 만든 기능이 올라가는게 아니고, 다른기능들이 계속 올라가서 굉장히 불편한데
> … 근본적으로는 SCV 쪽에 "slug 영상만 첨부" 옵션 이게 default였으면 좋겠다.

## 확인된 원인 (ai_tm_center 세션에서 스크립트 실측)

- pr-helper 는 `test-results/` 아래 `.webm/.mp4` 를 **전부** 찾아 첨부한다(slug 필터
  없음). report 도 같은 폴더를 수집한다.
- Playwright 는 실행마다 `test-results/` 를 비우므로, 거기엔 항상 "마지막 실행"의
  영상만 남는다. archive 직전 누적 회귀(옛 plan 들이 전체 스위트를 돎)를 돌리면
  마지막 실행 = 모든 기능 영상 → 그대로 PR/Slack 에 올라간다.

## 원하는 동작

- 기본: 이번 슬러그의 영상만 첨부. 전부 붙이고 싶은 팀만 `.env` 로 옛 방식.
- 슬러그 영상을 고르는 근거 후보: (a) per-slug E2E spec 규약(`<testDir>/<FOLDER_NAME>.spec.ts`,
  v0.16.0+) 덕에 Playwright 출력 폴더 이름이 슬러그로 시작한다 → 이름 필터;
  (b) 규약을 안 쓰는 프로젝트는 PR/report 직전에 그 plan 의 `## How to run` 을 한 번 더
  실행해 `test-results/` 를 이번 기능 영상으로만 채운 뒤 첨부.
- 슬러그 영상이 0건이면: 조용히 전부 붙이지 말고 한 줄 알리고 첨부 없이(또는 사용자
  선택) 진행.

## 열린 질문 (promote 때 확인)

- report 는 phase 단위라 슬러그를 모를 수 있다 — 인자/추론 규칙 필요.
- 스크린샷(PNG)도 같은 기준으로 좁힐지.
- 스위치 이름/기본값 (예: `SCV_ATTACHMENTS_SCOPE=slug|all`, 기본 slug).
