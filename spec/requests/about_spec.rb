require 'rails_helper'

RSpec.describe 'About', type: :request do
  describe 'GET /about' do
    it 'returns 200 OK' do
      get '/about'
      expect(response).to have_http_status(:ok)
    end
  end
end
