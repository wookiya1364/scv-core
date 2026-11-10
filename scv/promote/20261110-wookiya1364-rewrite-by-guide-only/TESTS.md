# Test Plan — 다시 쓰기는 가이드만

## Overview

요청을 다시 쓰는 길에서 항목 표와 낱말 규칙이 빠졌는지, 그러면서도 지금 있는 장치(등록 · 답 맨 위 인용 · 쓰기 문 · 종료 훅 · SCV 원칙의 내용)가 그대로 도는지 확인한다.
래퍼 쪽은 새 가이드 셋이 들어가고 기존 가이드 7개가 바뀌지 않았는지 확인한다.
코어 시나리오(T1–T14)는 새 시험 파일 하나에 모으고, 래퍼 시나리오(T15–T19)는 래퍼 저장소의 시험으로 돌린다.

## Test scenarios

### T1. 등록은 다시 쓴 요청과 범위만으로 통과한다

- **Setup**: 임시 프로젝트에 턴 표를 하나 만든다.
- **Run**: `model-prompting.sh register` 에 `scope | msg | …` 와 `rewrite | - | …` 두 줄만 넣는다.
- **Expected**: `REGISTERED:` 줄과 `REWRITE:` 줄이 나온다.
- **Pass criterion**: 종료 코드 0, 출력에 `missing` 이 0건.

### T2. 다시 쓴 요청이 없으면 등록이 실패한다

- **Setup**: T1 과 같다.
- **Run**: `scope` 한 줄만 넣는다.
- **Expected**: `missing rewrite` 가 찍힌다.
- **Pass criterion**: 종료 코드 0 이 아님, `REGISTERED:` 0건.

### T3. 범위가 없으면 등록이 실패한다

- **Setup**: T1 과 같다.
- **Run**: `rewrite` 한 줄만 넣는다.
- **Expected**: `missing scope` 가 찍힌다.
- **Pass criterion**: 종료 코드 0 이 아님, `REGISTERED:` 0건.

### T4. 옛 모양 등록도 통과한다

- **Setup**: T1 과 같다.
- **Run**: 옛 항목 8줄(goal · context · finish · scope · output · stop · act-or-suggest · depth)과 `rewrite` 를 넣는다.
- **Expected**: 항목 줄은 무시되고 등록된다.
- **Pass criterion**: 종료 코드 0, `REGISTERED:` 1건.

### T5. 범위가 '변경 없음'이면 프로젝트 파일 편집이 거절된다

- **Setup**: 범위를 `변경 없음 — 읽기만` 으로 등록한다. 다른 턴에서는 `core/x.sh 를 고침` 으로 등록한다.
- **Run**: 쓰기 문 판정을 두 턴에 각각 부른다.
- **Expected**: 첫 턴은 `forbidden`, 둘째 턴은 `ok`.
- **Pass criterion**: 두 값이 글자 그대로 나온다.

### T6. 매 턴 안내문에 항목 표 문구가 없다

- **Setup**: 가이드가 있는 모델 이름과 없는 모델 이름을 준비한다.
- **Run**: 매 턴 안내문을 두 모델로 만든다.
- **Expected**: 등록 명령과 "답 맨 위에 인용"은 남고, 항목을 나열하는 글은 없다.
- **Pass criterion**: `msg · ctx` · `1:1` · `checklist` · `항목 [` 이 각각 0건, `register` 가 1건 이상.

### T7. 낱말 규칙이 어디에도 실리지 않는다

- **Setup**: `SCV_LANG=korean` 인 임시 프로젝트.
- **Run**: `help.sh --with-context --model <가이드 있는 모델>` 을 부른다. 설정 예시와 계약 폴더를 훑는다.
- **Expected**: 도움말 출력에 `STE:` 가 없고, 낱말 규칙 문서가 없고, 설정 예시에 `SCV_REWRITE_STE` 가 없다.
- **Pass criterion**: 세 곳 모두 0건.

### T8. 옛 설정값이 남아 있어도 오류가 없다

- **Setup**: 프로젝트 설정에 `SCV_REWRITE_STE=on` 을 넣어 둔다.
- **Run**: 도움말과 등록을 한 번씩 부른다.
- **Expected**: 지금과 같이 돈다.
- **Pass criterion**: 두 명령 모두 종료 코드 0, 표준 오류에 `STE` 0건.

### T9. 다시 쓴 요청에 SCV 원칙 표식이 붙지 않는다

- **Setup**: `SCV_REWRITE_PRINCIPLE=on`.
- **Run**: 등록한다.
- **Expected**: `REWRITE:` 줄이 넣은 글과 같다.
- **Pass criterion**: `REWRITE:` 줄에 `[SCV 원칙 적용` 0건, 등록 출력에 원칙 전문 0줄.

### T10. SCV 원칙의 세 내용이 답 모양 안내에 그대로 있다

- **Setup**: `SCV_REWRITE_PRINCIPLE=on`, 새 컨텍스트의 첫 턴.
- **Run**: 매 턴 훅 출력을 받는다.
- **Expected**: 원칙 문서의 세 내용(사실 말하기 · 해결책 표 · 해로운 변경은 먼저 묻기)이 안내에 실린다.
- **Pass criterion**: 원칙 문서의 해당 구역 글이 훅 출력에 글자 그대로 들어 있다(줄 단위 대조, 차이 0줄).

### T11. 끝 메시지의 문제 표는 여전히 막힌다

- **Setup**: `SCV_REWRITE_PRINCIPLE=on`.
- **Run**: 문제 표가 든 끝 메시지로 원칙 문을 부른다. 해결책 표만 든 끝 메시지로도 부른다.
- **Expected**: 앞은 막고 뒤는 통과시킨다.
- **Pass criterion**: 지금 시험의 기대값과 같다.

### T12. 다시 쓴 요청 인용이 답 맨 위에 없으면 종료 훅이 막는다

- **Setup**: 등록한 턴.
- **Run**: 인용이 맨 위에 있는 답과 없는 답으로 종료 훅을 돌린다.
- **Expected**: 없는 답만 막힌다.
- **Pass criterion**: 지금 시험의 기대값과 같다.

### T13. 가이드가 없는 모델은 공통 발췌를 읽으라고 나온다

- **Setup**: 색인에 없는 모델 이름, 공통 가이드 줄이 있는 가이드 폴더.
- **Run**: `help.sh --with-context --model <없는 모델>`.
- **Expected**: 읽을 파일로 공통 가이드 발췌 하나가 나온다.
- **Pass criterion**: `GUIDE_FILE:` 줄이 1건이고 발췌 파일을 가리킨다. 가이드 폴더가 아예 없으면 지금처럼 `GUIDE: none`.

### T14. 매 턴 안내 분량이 늘지 않는다

- **Setup**: 지금 분량 한도 시험.
- **Run**: 분량 한도 시험을 돌린다.
- **Expected**: 통과한다. 매 턴 안내문의 바이트 수가 고치기 전보다 작거나 같다.
- **Pass criterion**: 시험 통과, 전후 바이트 수를 출력에 찍어 뒤가 앞 이하.

### T15. 래퍼 가이드 검사가 항목 표 없이 통과한다

- **Setup**: 래퍼 저장소, 항목 표 파일을 지운 상태.
- **Run**: `bash prompting/check.sh`.
- **Expected**: 모델 9개 · 파일 10개로 통과한다.
- **Pass criterion**: `OK prompting guides: 9 model id(s), 10 file(s)` 로 시작하는 줄, 종료 코드 0. 폴더에 `checklist-*.tsv` 0개.

### T16. 새 사본 셋이 원본과 같다

- **Setup**: 인터넷이 되는 곳.
- **Run**: `bash prompting/check.sh --online`.
- **Expected**: 본문이 원본과 바이트 단위로 같다.
- **Pass criterion**: 종료 코드 0, `differs` 0건.

### T17. 세 모델 이름으로 각자의 가이드가 나온다

- **Setup**: 래퍼의 가이드 폴더를 쓰는 임시 프로젝트.
- **Run**: `claude-fable-5-2` · `claude-sonnet-5-5` · `claude-haiku-5-5` 로 도움말을 부른다.
- **Expected**: 모델마다 자기 가이드 파일과 공통 발췌가 나온다.
- **Pass criterion**: 각 출력의 `GUIDE_FILE:` 줄에 `fable-5-2.md` · `sonnet-5-5.md` · `haiku-5-5.md` 가 1건씩.

### T18. 기존 6개 모델의 결과는 그대로다

- **Setup**: 고치기 전 판에서 6개 모델의 `GUIDE_FILE:` 줄을 받아 둔다.
- **Run**: 고친 판에서 같은 6개 모델로 부른다.
- **Expected**: 가리키는 파일이 같다.
- **Pass criterion**: 6개 모두 `GUIDE_FILE:` 줄이 전과 글자 그대로 같다. 기존 원문 사본 7개의 해시가 전과 같다.

### T19. 받을 대상을 고르면 그것만 받는다

- **Setup**: 래퍼 저장소.
- **Run**: `bash prompting/refresh.sh --dry-run fable-5-2 sonnet-5-5 haiku-5-5` 와 인자 없는 `--dry-run`.
- **Expected**: 앞은 세 줄, 뒤는 열 줄을 받겠다고 한다.
- **Pass criterion**: `would fetch:` 줄 수가 3 과 10. 실제로 셋만 받은 뒤 기존 사본 7개의 해시가 안 바뀐다.

### T20. 전후 글을 사용자에게 보인다

- **Setup**: 실제 요청 3개(질문 하나 · 고치라는 요청 하나 · 가리킴말이 든 요청 하나).
- **Run**: 고치기 전 판과 고친 판에서 각각 다시 쓴다.
- **Expected**: 두 글이 나란히 보인다.
- **Pass criterion**: 사용자가 본 뒤 "계속"을 고른다. 품질을 재는 것이 아니라 달라진 모습을 보이는 것이다.

### T21. 순수성 검사와 전체 시험

- **Setup**: 고친 코어.
- **Run**: 순수성 검사 · 목록 검사 · 전체 시험(bash 5 와 bash 3.2, 4개씩).
- **Expected**: 모두 통과한다.
- **Pass criterion**: 실패 0건. 목록 검사가 "목록 최신"을 찍는다.

## How to run

```bash
bash core/tests/test-rewrite-guide-only.sh && bash core/tests/test-model-prompting.sh && bash ../scv-claude-code/tests/test-model-prompting.sh && bash ../scv-claude-code/prompting/check.sh
```

## Pass criteria

- T1–T19 · T21 이 모두 통과한다.
- T20 은 사용자가 전후 글을 본 뒤 계속을 고른다.
- T16 은 인터넷이 필요하다. 안 되는 곳에서는 "확인 못 함"으로 적고 통과로 세지 않는다.

## Related Documents

- [`PLAN.md`](./PLAN.md)
- 측정 기록: `scv/raw/20261110-research-guide-table-measure.md`
