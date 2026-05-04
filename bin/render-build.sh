#!/usr/bin/env bash
# Render の buildCommand から呼ばれるビルドスクリプト。
# render.yaml の buildCommand に書くと長くなるため別ファイルに切り出している。
# errexit: 途中失敗で即座にビルド失敗扱いにする (= 不完全な状態で start させない)。

set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
# db:prepare = 「DB が無ければ create + 全 database (primary/cache/queue/cable) を migrate、
#               あれば migrate のみ」。初回デプロイと再デプロイ両方を 1 コマンドで対応。
bundle exec rails db:prepare
