# PR 을 만들어도 Slack 에는 증적이 없다

2026-08-25, ai_tm_center 실사용 보고.

역할 분담의 빈 구멍: CI 는 "실패만 증적" 정책(2026-08-24 결정), pr-helper 는
slug 영상을 GitHub PR 본문(orphan 브랜치)에만 첨부 — private 저장소라 거기선
인라인 재생도 안 되는데, Slack 에 올리는 주체가 아무도 없었다. 성공 증적은
세션이 수동으로 스레드에 올려 때웠다.

사용자 의도(확인됨): CI 는 E2E 실패만 Slack, 성공 slug 증적은 SCV 로컬이
Slack 에도 올려야 한다 — 성공했어도.

경계(사용자 합의): 프로젝트 봇(PR_manager)이 만든 스레드에 정밀 부착하는 건
스레드 번호를 아는 프로젝트 워크플로 몫. SCV 는 설정된 알림 채널에 PR 링크 +
slug 증적을 게시하는 것까지 담당한다 — 둘은 공존 가능.

재사용 가능한 부품: notifiers/ 어댑터 계약(post_message → thread_ref,
upload_file 스레드 업로드, NOTIFIER_DRY_RUN), 0.35.0 실행 기록(run manifest)
기반 증적 수집(pr-helper 의 VIDEOS/SCREENSHOTS 배열).
