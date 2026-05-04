require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # 表示時刻を JST に統一する。DB 保存は UTC のまま (= active_record.default_timezone デフォルト :utc を維持)。
    # DB を UTC で持つことで、将来海外ユーザー対応や per-user time_zone を導入する際の移行コストがゼロ。
    config.time_zone = "Tokyo"

    # I18n の標準ロケールを日本語に固定 (= rails-i18n gem で日本語化された各種フォーマットが効く)。
    # 主な効果: time_ago_in_words が「約 5 分」表記に / number_with_delimiter のロケール対応 / I18n.t の :ja 翻訳。
    # 将来海外展開時は per-user locale 切替を検討、まずは MVP として ja 固定。
    config.i18n.default_locale = :ja
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
