#!/usr/bin/env bash
# 공개 레포에 개인정보가 올라가지 않았는지 검사한다.
# PII_PATTERNS: 한 줄에 하나씩 확장 정규식(대소문자 무시). 패턴은 GitHub Secret에 두고
# 레포에는 두지 않는다. 출력에는 일치한 내용을 쓰지 않고 파일·커밋만 쓴다(CI 로그도 공개).
set -euo pipefail

if [ -z "${PII_PATTERNS:-}" ]; then
	echo "PII_PATTERNS 없음 — 검사 건너뜀(포크 PR이거나 Secret 미설정)"
	exit 0
fi
pats=$(mktemp)
trap 'rm -f "$pats"' EXIT
printf '%s\n' "$PII_PATTERNS" | sed '/^[[:space:]]*$/d' >"$pats"

fail=0
# 1. 현재 파일(LICENSE의 저작권 표기는 제외)
if files=$(git grep -lIiE -f "$pats" -- . ':!LICENSE'); then
	echo "개인정보 패턴이 있는 파일:"
	printf '  %s\n' $files
	fail=1
fi
# 2. 커밋 작성자·커미터·메시지(전체 기록)
bad=$(git rev-list HEAD | while read -r h; do
	git log -1 --format='%an %ae %cn %ce %B' "$h" | grep -qiE -f "$pats" && echo "${h:0:12}"
done || true)
if [ -n "$bad" ]; then
	echo "개인정보 패턴이 있는 커밋(작성자·메시지):"
	printf '  %s\n' $bad
	fail=1
fi
[ $fail -eq 0 ] && echo "개인정보 패턴 없음"
exit $fail
