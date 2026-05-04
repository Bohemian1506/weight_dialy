#!/usr/bin/env bash
# Render の buildCommand から呼ばれるビルドスクリプト。
# render.yaml の buildCommand に書くと長くなるため別ファイルに切り出している。
# errexit: 途中失敗で即座にビルド失敗扱いにする (= 不完全な状態で start させない)。

set -o errexit

bundle install
# Tailwind 4 + daisyUI 構成では `app/assets/tailwind/application.css` で `@plugin "daisyui";` を参照しており、
# tailwindcss:build (= assets:precompile の中で走る) が node_modules/daisyui を解決する必要がある。
# Render の Ruby buildpack は Node.js を同梱するが npm install は自動実行しないため、ここで明示する。
npm install
bundle exec rails assets:precompile
bundle exec rails assets:clean
# db:prepare = 「DB が無ければ create + 全 database (primary/cache/queue/cable) を migrate、
#               あれば migrate のみ」。初回デプロイと再デプロイ両方を 1 コマンドで対応。
bundle exec rails db:prepare
