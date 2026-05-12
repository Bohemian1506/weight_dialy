class CleanupOneTimeLoginTokensJob < ApplicationJob
  queue_as :default

  # TTL は 30s だが record は残る (= consume! が delete でなく used_at 更新のため)。
  # expires_at < 1.day.ago 一本で未使用 / 使用済問わず保持不要を網羅できる。
  # (Issue #176 では expired_or_used scope 案だったが、TTL 30s なら expires_at 一本で網羅できるため単純化)
  def perform
    OneTimeLoginToken.where("expires_at < ?", 1.day.ago).delete_all
  end
end
