class HomeController < ApplicationController
  def index
    @dashboard_state = determine_state
    @display_name    = current_user&.name || "ユウキ"
    @records         = fetch_records
    @today_record    = @records.find { |r| r.recorded_on == Date.current } || @records.last
    @streak          = StreakCalculatorService.call(@records)
    @advice          = CalorieAdviceService.call(@today_record&.estimated_kcal.to_i)
  end

  private

  def determine_state
    return :guest unless logged_in?

    platform = PlatformDetectorService.from_request(request)
    return :android if platform == :android
    return :iphone_with_data if current_user.step_records.exists?

    :empty
  end

  def fetch_records
    if @dashboard_state == :iphone_with_data
      current_user.step_records
                  .where(recorded_on: 30.days.ago.to_date..Date.current)
                  .order(:recorded_on)
                  .to_a
    else
      DemoDataService.sample_records
    end
  end
end
