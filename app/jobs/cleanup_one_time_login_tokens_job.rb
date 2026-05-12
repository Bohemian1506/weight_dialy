class CleanupOneTimeLoginTokensJob < ApplicationJob
  queue_as :default

  # TTL は 30s だが record は残る (= consume! が delete でなく used_at 更新のため)。
  # expires_at < 1.day.ago 一本で未使用 / 使用済問わず保持不要を網羅できる。
  def perform
    OneTimeLoginToken.where("expires_at < ?", 1.day.ago).delete_all
  end
end
