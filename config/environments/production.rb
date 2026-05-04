require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Render は SSL 終端を代行する (= Rails には HTTP で届く) ため、reverse proxy 前提で SSL 仮定する。
  config.assume_ssl = true

  # 全アクセスを HTTPS に揃え、Strict-Transport-Security と secure cookie を有効化。
  config.force_ssl = true

  # /up (Rails デフォルトの health check) は HTTPS リダイレクトをスキップ (= Render の health check が HTTP 経由のため)。
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Settings 画面の Webhook URL や mailer リンクで使う本番ホスト。Render 上では APP_HOST 環境変数で渡す。
  # フォールバックは Render が割当てるデフォルトドメイン (= 開発者がドメイン未設定でもデプロイ後即動作する)。
  app_host = ENV.fetch("APP_HOST", "weight-dialy.onrender.com")
  config.action_controller.default_url_options = { host: app_host, protocol: "https" }
  config.action_mailer.default_url_options     = { host: app_host, protocol: "https" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via bin/rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # DNS rebinding 対策。Render が割当てるドメイン + APP_HOST 設定値を許可。
  # 独自ドメイン後付け時は APP_HOST を変更すれば対応可能。
  config.hosts << app_host
  config.hosts << /\A[a-z0-9-]+\.onrender\.com\z/

  # /up (health check) は host チェックをスキップ (Render の health check で必要)。
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
