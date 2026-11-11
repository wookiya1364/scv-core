# Test Plan — 느린 순수함수 고치기

## Overview

고친 함수 17개가 고치기 전과 같은 답을 내는지, 그리고 정말 빨라졌는지를 본다.
답은 옛 본문을 그대로 옮긴 견줄 판(`core/tests/fixtures/slow-pure/reference.sh`)과 맞대고, 시간은 재는 명령(`pure-bench.sh`)으로 잰다.

## Test scenarios

### T1. 사전 예시에서 두 판의 답이 같다

- **Setup**: 사전(`scv/core/catalog/pure`)에서 17개 함수의 예시 인자를 읽는다
- **Run**: 예시 인자를 옛 본문(`ref_<이름>`)과 고친 본문에 넣는다
- **Expected**: 출력과 끝 코드가 같다
- **Pass criterion**: 17개 함수의 모든 예시에서 다름 0건

### T2. 큰 입력에서 두 판의 답이 같다

- **Setup**: 재는 명령이 만드는 1배(예시 25번) · 4배(예시 100번) 인자
- **Run**: 두 판에 넣는다 (옛 본문이 60초를 넘기는 앞쪽 충돌 검사의 4배 입력은 2배 입력으로 대신한다)
- **Expected**: 출력과 끝 코드가 같다
- **Pass criterion**: 다름 0건

### T3. 모서리 입력에서 두 판의 답이 같다

- **Setup**: 빈 글, 한 글자, 공백만, 한글 · 일본어 · 그림 글자가 섞인 글, 줄 끝이 없는 글, 빈 줄이 낀 글, 따옴표 · 괄호가 짝이 안 맞는 글, 같은 줄이 되풀이되는 목록
- **Run**: 함수마다 그 함수에 뜻이 있는 모서리 입력을 두 판에 넣는다
- **Expected**: 출력과 끝 코드가 같다
- **Pass criterion**: 다름 0건

### T4. 충돌 검사 둘은 큰 입력을 5초 안에 끝낸다

- **Setup**: 4배 입력 (고치기 전: 뒤쪽 23초, 앞쪽 60초 넘김)
- **Run**: 고친 두 함수를 한 번씩 돌린다
- **Expected**: 각각 5초 안에 끝난다
- **Pass criterion**: 걸린 시간 5초 미만 (붐비는 컴퓨터를 생각해 넉넉히 잡은 값)

### T5. 낱말 세기는 프로그램을 낱말 수만큼 부르지 않는다

- **Setup**: 낱말 51개 · 201개 입력
- **Run**: 재는 명령으로 부른 프로그램 수를 센다
- **Expected**: 낱말이 4배가 되어도 부른 수가 늘지 않는다 (고치기 전: 51번 → 201번)
- **Pass criterion**: 두 입력에서 부른 수가 같다

### T6. 순수 검사와 사전 검사

- **Setup**: 고친 뒤의 저장소
- **Run**: `check-purity.sh`, `pure-catalog.sh check`
- **Expected**: 선언과 다른 함수 0개, 사전과 코드가 같음, 예시가 모두 맞음
- **Pass criterion**: 두 명령 모두 끝 코드 0

### T7. 배수 기준 목록이 줄었다

- **Setup**: 두 셸에서 전체를 다시 잰 결과
- **Run**: 기준 목록(`scale-baseline.bash3` · `scale-baseline.bash5`)을 고치기 전(15개 · 11개)과 견준다
- **Expected**: 목록이 줄었고, 새로 들어온 이름이 없다
- **Pass criterion**: 두 목록 모두 고치기 전보다 짧고, 고치기 전에 없던 이름 0개

## How to run

```bash
bash core/tests/test-slow-pure-functions.sh
```

## Pass criteria

- 위 명령이 옛 셸(bash 3.2)과 새 셸(bash 5)에서 끝 코드 0
- 전체 시험이 두 셸에서 통과
- 17개의 앞뒤 시간 표가 계획 폴더에 있다
