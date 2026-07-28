#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for test_script in "$ROOT"/tests/test-*.sh; do
  echo "==> ${test_script##*/}"
  bash "$test_script"
done

echo "all SCV Core contract tests passed"
