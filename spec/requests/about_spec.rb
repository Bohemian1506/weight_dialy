require 'rails_helper'

# /about ページの request spec
# ポイント: request spec では response.body に HTML 文字列が入る。
#   include(...) でアプリ名やリンクの存在を確認するのが最小限の表示確認パターン。
RSpec.describe 'About', type: :request do
  describe 'GET /about' do
    before { get '/about' }

    it 'returns 200 OK' do
      expect(response).to have_http_status(:ok)
    end

    # アプリ名がページに表示されていることを確認する
    it 'includes the application name' do
      expect(response.body).to include('weight_dialy')
    end

    # ホームへ戻るリンクが href="/" として埋め込まれていることを確認する
    it 'includes a link back to the home page' do
      expect(response.body).to include('href="/"')
    end
  end
end
