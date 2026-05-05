class User < ApplicationRecord
  has_secure_token :webhook_token

  has_many :step_records, dependent: :destroy
  has_many :webhook_deliveries, dependent: :destroy   # プライバシー観点でユーザー削除時に全件削除 (Issue #84)

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :email, presence: true
  validates :name, presence: true

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.assign_attributes(
      email: auth.info.email,
      name: auth.info.name,
      image_url: auth.info.image
    )
    user.save!
    user
  end
end
