#!/usr/bin/env bash
# Claude Code PreToolUse hook
# Bash ツールで `git push ... main` を検知してブロックする。
# 二段構えガードの 1 段目 (Claude Code 経由)。
# 2 段目は .githooks/pre-push で人間の直接操作も阻止する。
#
# UX 設計判断 (PR #5 review): エラーメッセージの「正しい手順」は軽い 1 行追記で済ませており、
# 完全な場合分け (main にいる場合 / 作業ブランチにいる場合) は採用していない。
# 後輩スクール生から「混乱した」フィードバックが来たら、完全分岐に拡張する。

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
#   - `git push origin main` / `-u origin main` / `--force origin main`
#   - `git push origin HEAD:main` / `<sha>:main`
#   - `git push origin :main` (削除)
#   - `git push origin refs/heads/main` (full ref 形式)
#   - `git push --all` / `--mirror` (main を含めて全 ref を送る)
#
# 設計メモ: この hook は「早期検出」の役割で、本命の安全網は .githooks/pre-push 側。
# git は ref を解決してから pre-push を呼ぶため、どんな表記でも確実にブロックされる。
# Claude hook は早めに気付かせるためのものなので、よくある記法をカバーすれば十分。
if printf '%s' "$push_segments" | grep -Eq '(^|[[:space:]])main([[:space:]]|$)|:main([[:space:]]|$)|(^|[[:space:]])--(all|mirror)([[:space:]]|$)'; then
  cat >&2 <<'EOF'
🚫 main ブランチへの直接 push はブロックされました。

理由: weight_dialy では「main 直コミット禁止 / PR 経由マージ」の運用ルールを採用しています。
詳細: CLAUDE.md (プロジェクトルート) の「絶対ルール」を参照。

正しい手順:
  1. git checkout -b feature/<内容>     ← すでに作業ブランチにいる場合は 3 から
  2. 作業 → コミット
  3. git push -u origin feature/<内容>
  4. gh pr create --base main
EOF
  exit 2
fi

exit 0
