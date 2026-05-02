# Debugging / audit table that stores every inbound webhook request verbatim.
# Records are kept regardless of authentication outcome so operators can inspect
# what was received, replay missing records, and trace integration issues.
# Intentionally stores raw payload only — never derived PII such as user emails.
class WebhookDelivery < ApplicationRecord
  belongs_to :user, optional: true  # nil when authentication fails

  validates :status, inclusion: { in: %w[success unauthorized invalid] }
end
