class OneTimeLoginToken < ApplicationRecord
  # Phase 3 Capacitor OAuth ブリッジ用 (= Custom Tabs と Capacitor WebView の cookie storage 分離を超える)。
  # OAuth callback で session 作成後、Rails がここで token 発行 → custom URL scheme deep link で Capacitor app へ転送 →
  # WebView で /auto_login?token=XXX → consume! → WebView 側 cookie storage に session 確立、という一方向ブリッジ。
  TTL = 30.seconds

  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :unused, -> { where(used_at: nil) }
  scope :live,   -> { where("expires_at > ?", Time.current) }

  def self.issue!(user:)
    create!(
      user: user,
      token: SecureRandom.urlsafe_base64(32),
      expires_at: TTL.from_now
    )
  end

  # 一度だけ消費可能。期限切れ / 使用済みは nil を返し、呼び出し側で fail 扱い。
  # update_all で「未使用かつ未期限切れ」を SQL レベルでアトミックに条件付き更新する (= find → update の 2 ステップだと
  # 並行リクエストで両方が find を通過する race の余地が残るため、UPDATE ... WHERE used_at IS NULL に集約)。
  def self.consume!(token:)
    return nil if token.blank?
    updated = unused.live.where(token: token).update_all(used_at: Time.current)
    return nil if updated.zero?
    find_by(token: token)
  end

  # 以下の 2 メソッドは spec 可視性のための内部用 (= production code は consume! のみ呼ぶ)。
  # 状態遷移を読み取りやすくする教材性も兼ねている。
  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end
end
