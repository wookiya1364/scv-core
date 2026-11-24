#!/usr/bin/env bash
set -u
d="$1"; f="$2"; jobs="$3"; L="$4"
w="$(mktemp -d)"
( cd "$d" && git ls-files -z --cached --others --exclude-standard | while IFS= read -r -d '' p; do [ -f "$p" ] && mkdir -p "$w/$(dirname "$p")" && cp "$p" "$w/$p"; done )
grep -v -e '^dir ' -e '^$' "$f" > "$w/.cmds"
cat > "$w/.inner.sh" <<'EOF'
export LANG=C.UTF-8 GIT_TERMINAL_PROMPT=0
cd "$HOME/w" && git init -q . && git config user.email t@t && git config user.name t && git add -A >/dev/null 2>&1 && git commit -qm base >/dev/null 2>&1
n=0
while IFS= read -r c; do
  n=$((n + 1)); r=fail; JOBS="$JOBS" bash -c "$c" < /dev/null > "$HOME/w/.log-$n" 2>&1 && r=ok
  printf 'linux\t%s\t%s\t%s\n' "$r" "$c" "$LOGDIR/$n.log"
done < "$HOME/w/.cmds"
EOF
cat > "$w/.run.sh" <<'EOF'
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq git jq perl gawk bsdextrautils locales python3 nodejs rustc curl ca-certificates >/dev/null 2>&1 || { printf 'linux\tfail\t패키지 설치\t-\n'; exit 0; }
useradd -m ci && cp -R /w /home/ci/w && chown -R ci:ci /home/ci/w
su ci -c "JOBS='$JOBS' LOGDIR='$LOGDIR' bash /home/ci/w/.inner.sh"
cp /home/ci/w/.log-* /w/ 2>/dev/null
EOF
podman run --rm -e JOBS="$jobs" -e LOGDIR="$L" -v "$w":/w docker.io/library/ubuntu:24.04 bash /w/.run.sh 2>/dev/null | grep '^linux'
for l in "$w"/.log-*; do [ -f "$l" ] && cp "$l" "$L/${l##*/.log-}.log"; done
rm -rf "$w"
