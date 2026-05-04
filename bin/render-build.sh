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
# primary database (app_production) を作成 + schema 反映 + migration 実行。
bundle exec rails db:prepare

# A 案 (Solid Trifecta cache/queue/cable を primary DB に同居) の場合、`db:prepare` は
# cache/queue/cable の DATABASE_URL が primary と同じであることを「同 DB 処理済み」と判定して
# 各 _schema.rb をロードしない (Rails の multi-db 仕様)。
# 結果として solid_queue_jobs / solid_cache_entries / solid_cable_messages が作られず、
# Solid Queue supervisor が起動できず Puma 再起動ループに陥る。
# ここで明示的に各 schema を primary DB に load し、marker テーブル存在チェックで冪等性も確保する。
bundle exec rails runner '
  marker_tables = { cache: "solid_cache_entries", queue: "solid_queue_jobs", cable: "solid_cable_messages" }
  marker_tables.each do |db_name, marker|
    if ActiveRecord::Base.connection.table_exists?(marker)
      puts "[#{db_name}] schema already loaded, skipping"
    else
      schema_file = Rails.root.join("db/#{db_name}_schema.rb")
      if schema_file.exist?
        load schema_file
        puts "[#{db_name}] loaded #{schema_file.basename}"
      end
    end
  end
'
