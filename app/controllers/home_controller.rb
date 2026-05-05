class HomeController < ApplicationController
  def index
    data = BuildHomeDashboardService.call(user: current_user, request: request)
    @dashboard_state = data.state
    @display_name    = data.display_name
    @records         = data.records
    @today_record    = data.today_record
    @streak          = data.streak
    @advice          = data.advice
    @calorie_savings = data.calorie_savings
    @food_equivalent = data.food_equivalent
  end
end
