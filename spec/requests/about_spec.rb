require 'rails_helper'

RSpec.describe 'About', type: :request do
  describe 'GET /about' do
    before { get '/about' }

    it 'returns 200 OK' do
      expect(response).to have_http_status(:ok)
    end

    it 'includes the application name' do
      expect(response.body).to include('weight daily.')
    end

    it 'includes a link back to the home page' do
      expect(response.body).to include(root_path)
    end
  end
end
