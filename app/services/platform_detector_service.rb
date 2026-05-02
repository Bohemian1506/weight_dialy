# ユーザーエージェント文字列からアクセス端末プラットフォームを判定する。
# 実装の教材ポイント: 正規表現マッチだけで判定する軽量 Service。外部依存ゼロ。
# iOS 判定が Android より先なのは iPad など "iPad; CPU ... like Mac OS X" が Android を含まないため。
class PlatformDetectorService
  def self.from_request(request)
    ua = request.user_agent.to_s
    return :ios     if ua.match?(/iPhone|iPad|iPod/)
    return :android if ua.match?(/Android/)

    :other
  end
end
