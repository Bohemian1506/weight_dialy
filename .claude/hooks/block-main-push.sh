#!/usr/bin/env bash
# Claude Code PreToolUse hook
# Bash ツールで `git push ... main` を検知してブロックする。
# 二段構えガードの 1 段目 (Claude Code 経由)。
# 2 段目は .githooks/pre-push で人間の直接操作も阻止する。

set -euo pipefail

input=$(cat)

# JSON が不正な場合は通す (誤検知を避ける)。実運用の Claude Code 入力は常に正しい JSON。
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

if [[ -z "$command" ]]; then
  exit 0
fi

# `git push` を含むサブコマンドだけを抽出 (`;`, `&&`, `||`, `|` で区切る)
# commit メッセージ等に "main" を含むケースを誤検知しないよう、push の引数列だけを対象にする。
push_segments=$(printf '%s' "$command" | awk -v RS='[;&|]+' '/(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)/')

if [[ -z "$push_segments" ]]; then
  exit 0
fi

# main を destination とする push を検知:
#   - `git push origin main`
#   - `git push origin HEAD:main`
#   - `git push origin <sha>:main`
#   - `git push origin :main` (削除も阻止)
#   - `git push -u origin main`
#   - `git push --force origin main`
if printf '%s' "$push_segments" | grep -Eq '(^|[[:space:]])main([[:space:]]|$)|:main([[:space:]]|$)'; then
  cat >&2 <<'EOF'
🚫 main ブランチへの直接 push はブロックされました。

理由: weight_dialy では「main 直コミット禁止 / PR 経由マージ」の運用ルールを採用しています。
詳細: CLAUDE.md の「絶対ルール」を参照。

正しい手順:
  1. git checkout -b feature/<内容>
  2. 作業 → コミット → git push -u origin feature/<内容>
  3. gh pr create --base main
EOF
  exit 2
fi

exit 0
