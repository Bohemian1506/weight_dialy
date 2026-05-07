require "rails_helper"

# Issue #242 (= Tier 3 候補、PR #241 由来) で追加された service 単体 spec。
#
# 既存の `spec/requests/webhooks_spec.rb` (= 110 examples) は controller + service の統合テストとして
# 挙動保持を担保しているが、本 spec は **service の契約をコードでドキュメント化** することを主目的とする
# (= Day 9 学び 33 テスタビリティ軸: 「Service 切り出し時、別経路から呼ばれるようになったら独立 unit spec 追加」 の準備)。
#
# 役割分担:
#   - request spec (= webhooks_spec): HTTP 入出力 + 認証 + 監査ログ + ステータスコード等の controller 結合検証
#   - unit spec (= 本 spec): `.call` の引数 → 戻り値 / 例外 の純粋契約、private parse_* の境界値検証
RSpec.describe WebhookHealthDataIngestService do
  let(:user) { create(:user) }

  describe ".call" do
    # ─────────────────────────────────────────────────
    # 正常系: 戻り値 = accepted_count、副作用 = StepRecord upsert
    # ─────────────────────────────────────────────────
    context "正常系" do
      it "records_data が空配列 → accepted = 0、StepRecord 作成なし" do
        accepted = described_class.call(records_data: [], user: user)
        expect(accepted).to eq(0)
        expect(StepRecord.count).to eq(0)
      end

      it "1 件のレコード → accepted = 1、StepRecord 1 件作成" do
        records = [ { "recorded_on" => "2026-05-01", "steps" => 8000, "distance_meters" => 5000, "flights_climbed" => 12 } ]
        accepted = described_class.call(records_data: records, user: user)

        expect(accepted).to eq(1)
        expect(StepRecord.count).to eq(1)
        record = StepRecord.last
        expect(record.user).to eq(user)
        expect(record.recorded_on).to eq(Date.new(2026, 5, 1))
        expect(record.steps).to eq(8000)
        expect(record.distance_meters).to eq(5000)
        expect(record.flights_climbed).to eq(12)
      end

      it "複数レコード → accepted = N、StepRecord N 件作成" do
        records = [
          { "recorded_on" => "2026-05-01", "steps" => 8000 },
          { "recorded_on" => "2026-05-02", "steps" => 9000 },
          { "recorded_on" => "2026-05-03", "steps" => 7500 }
        ]
        accepted = described_class.call(records_data: records, user: user)

        expect(accepted).to eq(3)
        expect(StepRecord.count).to eq(3)
      end

      it "既存レコードがあれば update (= upsert: 同じ user + recorded_on で find_or_initialize_by)" do
        create(:step_record, user: user, recorded_on: Date.new(2026, 5, 1), steps: 1000)

        records = [ { "recorded_on" => "2026-05-01", "steps" => 9999 } ]
        accepted = described_class.call(records_data: records, user: user)

        expect(accepted).to eq(1)
        expect(StepRecord.count).to eq(1) # = 新規作成しない、既存を更新
        expect(StepRecord.last.steps).to eq(9999)
      end

      it "partial update: ペイロードに無い field は既存値を保持 (= absent ≠ 0 セマンティクス)" do
        # 既存レコード (steps=1000, distance_meters=500, flights_climbed=10)
        create(:step_record, user: user, recorded_on: Date.new(2026, 5, 1),
               steps: 1000, distance_meters: 500, flights_climbed: 10)

        # ペイロードは steps だけ送る
        records = [ { "recorded_on" => "2026-05-01", "steps" => 8000 } ]
        described_class.call(records_data: records, user: user)

        record = StepRecord.last
        expect(record.steps).to eq(8000)
        expect(record.distance_meters).to eq(500) # = 既存値保持
        expect(record.flights_climbed).to eq(10)  # = 既存値保持
      end

      it "整数値の Float (= 8000.0) は Integer に変換して保存" do
        records = [ { "recorded_on" => "2026-05-01", "steps" => 8000.0 } ]
        described_class.call(records_data: records, user: user)

        expect(StepRecord.last.steps).to eq(8000)
      end
    end

    # ─────────────────────────────────────────────────
    # 異常系: records_data が Array でない → InvalidPayload raise
    # ─────────────────────────────────────────────────
    context "InvalidPayload raise (= records_data の型不正)" do
      it "records_data が nil → raise + StepRecord 作成なし" do
        expect {
          described_class.call(records_data: nil, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, I18n.t("webhook.errors.missing_records_array"))
        expect(StepRecord.count).to eq(0)
      end

      it "records_data が Hash → raise" do
        expect {
          described_class.call(records_data: { "records" => [] }, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload)
      end

      it "records_data が文字列 → raise" do
        expect {
          described_class.call(records_data: "not an array", user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload)
      end
    end

    # ─────────────────────────────────────────────────
    # 異常系: recorded_on の形式不正 → InvalidPayload raise (= 旧 parse_recorded_on の境界値)
    # ─────────────────────────────────────────────────
    context "InvalidPayload raise (= recorded_on の形式不正)" do
      it "recorded_on が nil → required エラー" do
        records = [ { "recorded_on" => nil, "steps" => 8000 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, I18n.t("webhook.errors.recorded_on_required"))
      end

      it "recorded_on が空文字 → required エラー" do
        records = [ { "recorded_on" => "", "steps" => 8000 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, I18n.t("webhook.errors.recorded_on_required"))
      end

      it "recorded_on が ISO 8601 以外 (= 2026/05/01) → invalid_format" do
        records = [ { "recorded_on" => "2026/05/01", "steps" => 8000 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, I18n.t("webhook.errors.recorded_on_invalid_format"))
      end

      it "recorded_on の zero padding 不足 (= 2026-5-1) → invalid_format" do
        # Date.strptime は zero padding 不足を許容するが、本 service は ISO_DATE_FORMAT 正規表現で先に reject
        records = [ { "recorded_on" => "2026-5-1", "steps" => 8000 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, I18n.t("webhook.errors.recorded_on_invalid_format"))
      end

      it "recorded_on が月日値域違反 (= 2026-13-99) → invalid_format (Date::Error rescue 経由)" do
        records = [ { "recorded_on" => "2026-13-99", "steps" => 8000 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, I18n.t("webhook.errors.recorded_on_invalid_format"))
      end
    end

    # ─────────────────────────────────────────────────
    # 異常系: 数値フィールド型不正 → InvalidPayload raise (= 旧 parse_numeric の境界値)
    # Apple HealthKit Sample object `{ value: 12345, unit: "count" }` のような silent 0 化を防ぐ
    # ─────────────────────────────────────────────────
    context "InvalidPayload raise (= 数値フィールド型不正)" do
      it "steps が Hash (= HealthKit Sample object 風) → raise (= silent 0 化防止)" do
        records = [ { "recorded_on" => "2026-05-01", "steps" => { "value" => 12345, "unit" => "count" } } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, /must_be_number|数値|number/i)
      end

      it "distance_meters が文字列 → raise" do
        records = [ { "recorded_on" => "2026-05-01", "distance_meters" => "5000" } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload)
      end

      it "flights_climbed が小数値 Float (= 9999.9) → raise (= silent 切り捨て防止、整数値 Float は別途許容)" do
        records = [ { "recorded_on" => "2026-05-01", "flights_climbed" => 9999.9 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload, /whole_number|整数/i)
      end

      it "steps が nil は許容 (= raise しない、partial update セマンティクス)" do
        # nil は parse_numeric が return nil → updates から compact で除外、
        # 新規レコードは schema default (= 0) が入る。partial update の真価は既存レコードへの上書きで現れる
        # (= 上の正常系「partial update: ペイロードに無い field は既存値を保持」 で検証済)。
        records = [ { "recorded_on" => "2026-05-01", "steps" => nil, "distance_meters" => 5000 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.not_to raise_error
        expect(StepRecord.last.distance_meters).to eq(5000)
      end
    end

    # ─────────────────────────────────────────────────
    # ActiveRecord::RecordInvalid は service で rescue せず controller に委譲
    # (= バリデーション違反 = 全体失敗方式、controller 側で 422 + 監査ログ "invalid" 経路へ)
    # ─────────────────────────────────────────────────
    context "ActiveRecord::RecordInvalid を controller に委譲" do
      it "負数 steps は AR バリデーションで raise (= service は rescue しない)" do
        records = [ { "recorded_on" => "2026-05-01", "steps" => -100 } ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    # ─────────────────────────────────────────────────
    # トランザクション境界: 1 件失敗で全件ロールバック (= all-or-nothing)
    # 「リトライ時に同じペイロードを安全に再送できる」 セマンティクスを保証
    # ─────────────────────────────────────────────────
    context "トランザクション境界 (= 1 件失敗で全件ロールバック)" do
      it "2 件中 2 件目が AR バリデーション違反 → 1 件目もロールバック (= StepRecord 0 件)" do
        records = [
          { "recorded_on" => "2026-05-01", "steps" => 8000 },
          { "recorded_on" => "2026-05-02", "steps" => -100 } # 負数 → AR バリデーション違反
        ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(StepRecord.count).to eq(0) # = 1 件目も保存されていない
      end

      it "3 件中 2 件目が parse 失敗 → 1 件目もロールバック (= InvalidPayload も transaction 内で発生)" do
        records = [
          { "recorded_on" => "2026-05-01", "steps" => 8000 },
          { "recorded_on" => "2026/05/02", "steps" => 9000 }, # 形式不正 → InvalidPayload
          { "recorded_on" => "2026-05-03", "steps" => 7500 }
        ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(WebhookHealthDataIngestService::InvalidPayload)

        expect(StepRecord.count).to eq(0)
      end

      it "既存レコードがある状態で失敗 → 既存レコードは変更されない" do
        existing = create(:step_record, user: user, recorded_on: Date.new(2026, 5, 1), steps: 1000)

        records = [
          { "recorded_on" => "2026-05-01", "steps" => 9999 }, # 既存を更新する予定
          { "recorded_on" => "2026-05-02", "steps" => -100 }  # 失敗
        ]
        expect {
          described_class.call(records_data: records, user: user)
        }.to raise_error(ActiveRecord::RecordInvalid)

        expect(existing.reload.steps).to eq(1000) # = 更新されていない
      end
    end
  end
end
