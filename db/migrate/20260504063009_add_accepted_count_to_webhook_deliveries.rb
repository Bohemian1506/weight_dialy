class AddAcceptedCountToWebhookDeliveries < ActiveRecord::Migration[8.1]
  # WebhookDelivery 1 件で「何件保存できたか」を記録する。
  # success 時は upsert_records が返した accepted 数、reject 時は 0 (or nil)。
  # success ログに accepted_count = 0 が混ざると「実質意味のないペイロード」(= 全件 silent skip 等) を後追い分析できる。
  # Issue #52 (= Day 3-3 の code-reviewer 指摘 ⚠️3 由来)。
  def change
    add_column :webhook_deliveries, :accepted_count, :integer
  end
end
