#!/usr/bin/env bash
awk -F'\t' '$2 == "fail" { bad = bad "  " $1 " 실패: " $3 " (기록 " $4 ")\n" } NF { n++ } END { if (bad != "" || !n) { printf "%sRELEASE_BLOCKED: %s\n", bad, (n ? "실패한 명령이 있다" : "결과가 없다") > "/dev/stderr"; exit 1 } printf "RELEASE_OK: %d개 통과\n", n }'
