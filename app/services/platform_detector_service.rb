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

  # Capacitor アプリ起動時の overrideUserAgent には "Android" + "WeightDialyCapacitor" が含まれるため、
  # 「Web 版 Android UA」は Android かつ WeightDialyCapacitor 不在で判定する。
  # Issue #184 (= Settings に Web Android user 向け案内セクション出し分け) で使用。
  def self.web_android?(request)
    ua = request.user_agent.to_s
    ua.match?(/Android/) && !ua.match?(/WeightDialyCapacitor/)
  end
end
