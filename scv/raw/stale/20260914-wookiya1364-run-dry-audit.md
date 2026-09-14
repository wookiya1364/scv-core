# run-dry 단언 981개 감사 (2026-09-14)

출처: 이 세션 실측 (core/tests/run-dry.sh, 4,036행, 섹션 68).

- 종류: assert_contains 453 · assert_out_contains 214 · assert_file 27 · 루프 pass/fail
- 규약 문장 고정(assert_contains on *_CMD/PROTOCOL_ROOT 등) 353: 토큰·플래그·제목 208 · 문장(6단어↑) 71 · mermaid 8
  · 규약에서 찾은 306 중 GUIDANCE 블록 안에만 있는 것 80 (minimal 프로필에선 잘려나가는 코칭 문구)
- 규약별: promote 151 · work 74 · PROMOTE.md 31 · help 28+10 · regression 19 · pr-helper 17 · codegen 13
- 가장 큰 섹션 셋: [11bbb] mermaid 매핑 66 · [11hhh] mermaid dark-theme 63 · [11aaa] FEATURE_ARCHITECTURE 58 = 187
- 정확히 같은 (파일, 문자열) 중복 3: $ENV_EX/SCV_PROMOTE_LANG · $ENV_EXAMPLE/CONFLUENCE_BASE_URL · $ENV_EXAMPLE/SCV_FAST_PATH_LINE_THRESHOLD
- 전용 검사(help-shape · force-help · delegate)와 겹치는 help 앵커: 38 중 1
- 섹션 머리에 버전이 적힌 것 10/68
- 마찰 실측: help 다이어트(본문 28→13KB)에 앵커 10개 재조준. promote(69KB) 다이어트면 ~151개.
