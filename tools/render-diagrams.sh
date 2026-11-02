#!/usr/bin/env bash
# render-diagrams.sh — README 그림 원본(.mmd)을 같은 이름의 SVG 로 다시 뽑는다.
#
# GitHub 휴대폰 앱은 머메이드를 그리지 않아 README 에는 SVG 이미지를 넣고, 원본은 assets/diagrams/*.mmd 로 둔다.
# 원본을 고쳤으면 이것으로 SVG 를 다시 뽑아 함께 커밋한다(README 검사는 원본 · 이미지가 짝으로 있는지만 본다).
#
# 쓰기: tools/render-diagrams.sh [<assets/diagrams 폴더>]   (기본: 이 저장소의 assets/diagrams)
# 필요: node(npx) · 크롬. 크롬 위치는 PUPPETEER_EXECUTABLE_PATH, 없으면 맥의 Google Chrome, 그것도 없으면
#       mermaid-cli 가 받은 크롬을 쓴다.
# 글자는 SVG 의 text 로 그린다(htmlLabels 끔) — 이미지로만 보여 주는 곳은 HTML 글자를 그리지 않는다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${1:-$ROOT/assets/diagrams}"
[[ -d "$DIR" ]] || { echo "✖ $DIR not found" >&2; exit 2; }
command -v npx >/dev/null || { echo "✖ npx not found (install Node.js)" >&2; exit 2; }

MMDC="@mermaid-js/mermaid-cli@11.4.0"
BG="#171922"   # 그림 원본의 init 배경과 같다
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf '%s\n' '{"htmlLabels":false,"flowchart":{"htmlLabels":false}}' > "$TMP/config.json"

chrome="${PUPPETEER_EXECUTABLE_PATH:-}"
mac_chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[[ -z "$chrome" && -x "$mac_chrome" ]] && chrome="$mac_chrome"
pp=()
if [[ -n "$chrome" ]]; then
  printf '{"executablePath":"%s","args":["--no-sandbox"]}\n' "$chrome" > "$TMP/puppeteer.json"
  pp=(-p "$TMP/puppeteer.json")
fi

n=0
for src in "$DIR"/*.mmd; do
  [[ -e "$src" ]] || continue
  out="${src%.mmd}.svg"
  npx -y "$MMDC" -q ${pp[@]+"${pp[@]}"} -c "$TMP/config.json" -b "$BG" -i "$src" -o "$out"
  grep -q '<svg' "$out" || { echo "✖ $out is not an SVG" >&2; exit 1; }
  n=$((n + 1))
  echo "rendered ${out#"$ROOT"/}"
done
(( n > 0 )) || { echo "✖ no .mmd in $DIR" >&2; exit 1; }
echo "OK render-diagrams: $n diagram(s)"
