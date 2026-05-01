class User < ApplicationRecord
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
