require "rails_helper"

RSpec.describe "POST /webhooks/health_data", type: :request do
  let(:user) { create(:user) }
  let(:valid_headers) do
    {
      "Authorization" => "Bearer #{user.webhook_token}",
      "Content-Type" => "application/json"
    }
  end

  def post_health_data(body, headers: valid_headers)
    post "/webhooks/health_data", params: body.is_a?(String) ? body : body.to_json, headers: headers
  end

  # ---------------------------------------------------------------------------
  # Shared examples for unauthorized requests
  # ---------------------------------------------------------------------------
  shared_examples "rejects unauthorized request" do
    it "returns HTTP 401" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the Unauthorized error body" do
      expect(response.parsed_body).to eq("error" => "Unauthorized")
    end

    it "does not create any StepRecord" do
      expect(StepRecord.count).to eq(0)
    end

    it "records a WebhookDelivery with status 'unauthorized'" do
      expect(WebhookDelivery.last.status).to eq("unauthorized")
    end

    it "records the WebhookDelivery with user = nil (PII protection)" do
      expect(WebhookDelivery.last.user).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # Case 1: Successful authentication + single record upsert
  # ---------------------------------------------------------------------------
  describe "Case 1: valid token, single record" do
    let(:payload) do
      { records: [ { recorded_on: "2026-05-01", steps: 8000, distance_meters: 5000, flights_climbed: 12 } ] }
    end

    before { post_health_data(payload) }

    it "returns HTTP 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns accepted: 1" do
      expect(response.parsed_body).to eq("accepted" => 1)
    end

    it "creates 1 StepRecord" do
      expect(StepRecord.count).to eq(1)
    end

    it "saves the StepRecord with correct attributes" do
      record = StepRecord.last
      expect(record.steps).to eq(8000)
      expect(record.distance_meters).to eq(5000)
      expect(record.flights_climbed).to eq(12)
      expect(record.recorded_on).to eq(Date.new(2026, 5, 1))
    end

    it "records a WebhookDelivery with status 'success'" do
      expect(WebhookDelivery.last.status).to eq("success")
    end

    it "records the WebhookDelivery linked to the authenticated user" do
      expect(WebhookDelivery.last.user).to eq(user)
    end
  end

  # ---------------------------------------------------------------------------
  # Case 2: No Authorization header → 401
  # ---------------------------------------------------------------------------
  describe "Case 2: missing Authorization header" do
    before do
      post_health_data(
        { records: [] },
        headers: { "Content-Type" => "application/json" }
      )
    end

    include_examples "rejects unauthorized request"
  end

  # ---------------------------------------------------------------------------
  # Case 3: Wrong token → 401
  # ---------------------------------------------------------------------------
  describe "Case 3: invalid Bearer token" do
    before do
      post_health_data(
        { records: [] },
        headers: {
          "Authorization" => "Bearer wrong_token",
          "Content-Type" => "application/json"
        }
      )
    end

    include_examples "rejects unauthorized request"
  end

  # ---------------------------------------------------------------------------
  # Case 4: Multiple records in a single request
  # ---------------------------------------------------------------------------
  describe "Case 4: multiple records in one request" do
    let(:payload) do
      {
        records: [
          { recorded_on: "2026-05-01", steps: 6000, distance_meters: 4000, flights_climbed: 5 },
          { recorded_on: "2026-05-02", steps: 7000, distance_meters: 4500, flights_climbed: 8 },
          { recorded_on: "2026-05-03", steps: 9000, distance_meters: 6000, flights_climbed: 15 }
        ]
      }
    end

    before { post_health_data(payload) }

    it "returns HTTP 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns accepted: 3" do
      expect(response.parsed_body).to eq("accepted" => 3)
    end

    it "creates 3 StepRecords" do
      expect(StepRecord.count).to eq(3)
    end
  end

  # ---------------------------------------------------------------------------
  # Case 5: Same day re-POST → upsert (overwrite)
  # ---------------------------------------------------------------------------
  describe "Case 5: re-posting same recorded_on updates the existing record" do
    let(:date) { "2026-05-01" }

    before do
      post_health_data({ records: [ { recorded_on: date, steps: 5000, distance_meters: 3000, flights_climbed: 4 } ] })
      post_health_data({ records: [ { recorded_on: date, steps: 8000, distance_meters: 6000, flights_climbed: 10 } ] })
    end

    it "keeps only 1 StepRecord for the date" do
      expect(StepRecord.where(user: user, recorded_on: date).count).to eq(1)
    end

    it "updates steps to the new value" do
      expect(StepRecord.find_by(user: user, recorded_on: date).steps).to eq(8000)
    end

    it "updates distance_meters to the new value" do
      expect(StepRecord.find_by(user: user, recorded_on: date).distance_meters).to eq(6000)
    end
  end

  # ---------------------------------------------------------------------------
  # Case 6a: Partial payload — only steps sent, existing values preserved
  # ---------------------------------------------------------------------------
  describe "Case 6a: partial payload overwrites only supplied keys on existing record" do
    let(:date) { "2026-05-01" }

    before do
      # Create initial record with all fields
      create(:step_record, user: user, recorded_on: date, steps: 5000, distance_meters: 3000, flights_climbed: 6)
      # Re-send with only steps; distance_meters and flights_climbed omitted
      post_health_data({ records: [ { recorded_on: date, steps: 9000 } ] })
    end

    it "returns HTTP 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates steps" do
      expect(StepRecord.find_by(user: user, recorded_on: date).steps).to eq(9000)
    end

    it "preserves the original distance_meters" do
      expect(StepRecord.find_by(user: user, recorded_on: date).distance_meters).to eq(3000)
    end

    it "preserves the original flights_climbed" do
      expect(StepRecord.find_by(user: user, recorded_on: date).flights_climbed).to eq(6)
    end
  end

  # ---------------------------------------------------------------------------
  # Case 6b: Partial payload — new record, missing keys default to 0
  # ---------------------------------------------------------------------------
  describe "Case 6b: partial payload creates new record with DB defaults for missing keys" do
    let(:date) { "2026-05-01" }

    before { post_health_data({ records: [ { recorded_on: date, steps: 4000 } ] }) }

    it "creates the StepRecord" do
      expect(StepRecord.where(user: user, recorded_on: date).count).to eq(1)
    end

    it "saves the supplied steps" do
      expect(StepRecord.find_by(user: user, recorded_on: date).steps).to eq(4000)
    end

    it "sets distance_meters to 0 (DB default)" do
      expect(StepRecord.find_by(user: user, recorded_on: date).distance_meters).to eq(0)
    end

    it "sets flights_climbed to 0 (DB default)" do
      expect(StepRecord.find_by(user: user, recorded_on: date).flights_climbed).to eq(0)
    end
  end

  # ---------------------------------------------------------------------------
  # Case 7: Invalid JSON body → 422
  # ---------------------------------------------------------------------------
  describe "Case 7: invalid JSON body" do
    before do
      post_health_data(
        "not json",
        headers: {
          "Authorization" => "Bearer #{user.webhook_token}",
          "Content-Type" => "application/json"
        }
      )
    end

    it "returns HTTP 422" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns the Invalid payload error body" do
      expect(response.parsed_body).to eq("error" => "Invalid payload")
    end

    it "does not create any StepRecord" do
      expect(StepRecord.count).to eq(0)
    end

    it "records a WebhookDelivery with status 'invalid'" do
      expect(WebhookDelivery.last.status).to eq("invalid")
    end

    it "includes 'JSON parse error' in the error_message" do
      expect(WebhookDelivery.last.error_message).to include("JSON parse error")
    end
  end

  # ---------------------------------------------------------------------------
  # Case 8: Missing 'records' key → 422
  # ---------------------------------------------------------------------------
  describe "Case 8: JSON body without 'records' array" do
    before { post_health_data({ foo: "bar" }) }

    it "returns HTTP 422" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns the Invalid payload error body" do
      expect(response.parsed_body).to eq("error" => "Invalid payload")
    end

    it "records a WebhookDelivery with status 'invalid'" do
      expect(WebhookDelivery.last.status).to eq("invalid")
    end

    it "includes 'missing records array' context in the error_message" do
      expect(WebhookDelivery.last.error_message).to include("missing 'records' array")
    end
  end

  # ---------------------------------------------------------------------------
  # Case 9: Entry without recorded_on is silently skipped
  # ---------------------------------------------------------------------------
  describe "Case 9: entries missing recorded_on are silently skipped" do
    let(:payload) do
      {
        records: [
          { recorded_on: "2026-05-01", steps: 100 },
          { steps: 200 },                             # no recorded_on → skip
          { recorded_on: "2026-05-02", steps: 300 }
        ]
      }
    end

    before { post_health_data(payload) }

    it "returns HTTP 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns accepted: 2 (skipped entry not counted)" do
      expect(response.parsed_body).to eq("accepted" => 2)
    end

    it "creates exactly 2 StepRecords" do
      expect(StepRecord.count).to eq(2)
    end

    it "does not create a record for the entry missing recorded_on" do
      created_dates = StepRecord.pluck(:recorded_on)
      expect(created_dates).to contain_exactly(Date.new(2026, 5, 1), Date.new(2026, 5, 2))
    end

    # NOTE: This 'silent skip' behavior was a deliberate judgment call by
    # rails-implementer. If the spec changes to return an error instead,
    # update this example and Case 9 as a pair.
  end

  # ---------------------------------------------------------------------------
  # Case 10: Validation failure on a record (e.g., negative steps) → 422 + audit
  # ---------------------------------------------------------------------------
  # 個々のレコードのバリデーション違反は ActiveRecord::RecordInvalid を rescue して
  # 422 + WebhookDelivery(invalid) で返す方針 (500 で audit log 取れない事態を避ける)。
  describe "Case 10: invalid record attribute (negative steps) returns 422" do
    before do
      post_health_data({ records: [ { recorded_on: "2026-05-01", steps: -100 } ] })
    end

    it "returns HTTP 422" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns the Invalid payload error body" do
      expect(response.parsed_body).to eq("error" => "Invalid payload")
    end

    it "does not create any StepRecord" do
      expect(StepRecord.count).to eq(0)
    end

    it "records a WebhookDelivery with status 'invalid'" do
      expect(WebhookDelivery.last.status).to eq("invalid")
    end

    it "includes 'RecordInvalid' in the error_message" do
      expect(WebhookDelivery.last.error_message).to include("RecordInvalid")
    end
  end

  # ---------------------------------------------------------------------------
  # Case 11: All-or-nothing — 1 件失敗で全件 rollback
  # ---------------------------------------------------------------------------
  describe "Case 11: transaction rollback when middle record fails validation" do
    before do
      post_health_data({
        records: [
          { recorded_on: "2026-05-01", steps: 1000 },
          { recorded_on: "2026-05-02", steps: -50 },   # 違反
          { recorded_on: "2026-05-03", steps: 3000 }
        ]
      })
    end

    it "returns HTTP 422" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rolls back ALL records, leaving 0 in DB" do
      expect(StepRecord.count).to eq(0)
    end

    it "records a single WebhookDelivery with status 'invalid'" do
      expect(WebhookDelivery.where(status: "invalid").count).to eq(1)
    end
  end

  # ---------------------------------------------------------------------------
  # Case 12: Body size limit (1MB) — DoS guard
  # ---------------------------------------------------------------------------
  describe "Case 12: payload exceeding 1MB returns 413" do
    let(:huge_body) do
      # 1MB をわずかに超える JSON を生成 (records 配列に dummy entries を詰める)
      huge_string = "x" * (1.megabyte + 100)
      { records: [ { recorded_on: "2026-05-01", steps: 1, note: huge_string } ] }.to_json
    end

    before { post_health_data(huge_body) }

    it "returns HTTP 413" do
      expect(response).to have_http_status(:content_too_large)
    end

    it "returns the Payload too large error body" do
      expect(response.parsed_body).to eq("error" => "Payload too large")
    end

    it "does not create any StepRecord" do
      expect(StepRecord.count).to eq(0)
    end
  end
end
