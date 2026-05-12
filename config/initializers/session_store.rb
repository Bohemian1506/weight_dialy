# expire_after: 2 週間 = 通勤通学カジュアル層 (= 週末しか開かない / 月 1-2 ペース利用者) を想定。
# 詳細根拠 = Issue #320。将来 Devise 風 "Remember me" cookie を追加する際は、本値を短縮 (or 撤去)
# し、長期化は Remember me cookie 側で管理する方針 (= 「チェック有 = 長期 / 無 = ブラウザセッション」
# の選択 UI が一般的なため、cookie_store 自体を一律長期にしておくと並立で破綻する)。
#
# same_site: :lax = Google OAuth callback は GET ルート (= routes.rb の auth_callback path) のため
# トップレベル GET ナビゲーションとして cookie が送られる。OmniAuth の allowed_request_methods = [:post]
# は request phase (= 自サイトへの同サイト POST) の CSRF 対策であり callback phase とは別軸。
# 仮に callback が POST だった場合は same_site: :none + secure: true への変更が必要だった。
Rails.application.config.session_store :cookie_store,
  key: "_weight_dialy_session",
  expire_after: 2.weeks,
  secure: Rails.env.production?,
  same_site: :lax
