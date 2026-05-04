class HomeController < ApplicationController
  def index
    @dashboard_state = determine_state
    @display_name    = current_user&.name || "ユウキ"
    @records         = fetch_records(@dashboard_state)
    @today_record    = @records.find { |r| r.recorded_on == Date.current } || @records.last
    @streak          = StreakCalculatorService.call(@records)
    @advice          = CalorieAdviceService.call(@today_record&.estimated_kcal.to_i)
    # 貯カロリー (= 月リセット + 累計の二段構造) はチャート用 30 日 records とは別に
    # 全期間 records を渡して算出する (= 累計 total は全期間でないと意味が出ないため)。
    @calorie_savings = CalorieSavingsService.call(fetch_calorie_records(@dashboard_state))
  end

  private

  def determine_state
    return :guest unless logged_in?

    platform = PlatformDetectorService.from_request(request)
    return :android if platform == :android
    return :iphone_with_data if current_user.step_records.exists?

    :empty
  end

  # 状態を引数で明示的に受け取って暗黙の呼び出し順依存を排除する。
  def fetch_records(state)
    if state == :iphone_with_data
      current_user.step_records
                  .where(recorded_on: 30.days.ago.to_date..Date.current)
                  .order(:recorded_on)
                  .to_a
    else
      DemoDataService.call
    end
  end

  # 貯カロリー算出用の records は 全期間 を返す (= 累計 total を正確に計算するため)。
  # demo state では demo の 30 日分 (= fetch_records と同一) で代替。
  def fetch_calorie_records(state)
    if state == :iphone_with_data
      current_user.step_records.order(:recorded_on).to_a
    else
      DemoDataService.call
    end
  end
end
