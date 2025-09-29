require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.colorize_logging = true

    # 日本時間に設定
    config.time_zone = "Tokyo"

    # データベースへの保存時刻をローカルタイムゾーンに合わせる
    config.active_record.default_timezone = :local

    # 日本語をデフォルトロケールに設定
    config.i18n.default_locale = :ja

    # Strong Parametersのエラー時に例外を発生させる（開発環境での設定漏れ防止）
    config.action_controller.action_on_unpermitted_parameters = :raise if Rails.env.development? || Rails.env.test?

    # ジェネレーター設定
    config.generators do |g|
      g.test_framework false  # テストファイルを生成しない
      g.helper false         # ヘルパーファイルを生成しない
      g.assets false         # アセットファイルを生成しない
      g.jbuilder false       # jbuilderファイルを生成しない
    end
  end
end
