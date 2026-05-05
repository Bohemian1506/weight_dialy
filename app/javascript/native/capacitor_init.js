// Capacitor アプリ初期化処理 (= Phase 3: @capacitor/browser ベース OAuth ブリッジ)
//
// 目的: Custom Tabs と Capacitor WebView の cookie storage 分離問題を、custom URL scheme deep link +
//       one-time login token の往復で解決する。
//
// フロー:
// 1. ユーザーが WebView の Google ログインボタンをタップ
// 2. capacitor_oauth_login_controller (Stimulus) が click を intercept、Browser.open で /auth/capacitor_start を Custom Tabs で開く
// 3. Rails が Custom Tabs cookie に capacitor_oauth フラグを焼き、/auth/google_oauth2 に POST を自動 submit
// 4. Google OAuth 完了 → callback で OneTimeLoginToken 発行 → com.weightdialy.app://oauth_callback?token=XXX へ redirect
// 5. Android が custom scheme を認識して Custom Tabs を自動 close、Capacitor アプリ前面復帰
// 6. ↓ 本ファイルの appUrlOpen handler で token 受信 → Browser.close (iOS 念のため) → WebView を /auto_login?token=XXX に navigate
// 7. Rails /auto_login で token 消費 + WebView 側 cookie storage に session 確立 → / にリダイレクト

const CUSTOM_SCHEME_PREFIX = "com.weightdialy.app://"

if (typeof window.Capacitor !== "undefined" && window.Capacitor.isNativePlatform?.()) {
  const App = window.Capacitor.Plugins.App
  const Browser = window.Capacitor.Plugins.Browser

  if (App && typeof App.addListener === "function") {
    App.addListener("appUrlOpen", async (data) => {
      // OAuth callback URL には ?token=... が含まれるため console.log は使わない (= Logcat / DevTools 経由で露出する、token は 30s + 1 回限りで失効するが本番ログ汚染を避ける)
      console.debug("[Capacitor] appUrlOpen received")
      const url = data?.url
      if (!url) return

      try {
        if (url.startsWith(CUSTOM_SCHEME_PREFIX)) {
          // Phase 3 メイン経路: custom URL scheme で OAuth callback 受信
          const parsed = new URL(url)
          const token = parsed.searchParams.get("token")
          if (!token) {
            console.warn("[Capacitor] custom scheme received without token")
            return
          }
          // iOS は Browser.close 必須、Android は no-op だが副作用なし
          if (Browser && typeof Browser.close === "function") {
            try { await Browser.close() } catch (_) { /* close 失敗は致命的でない */ }
          }
          window.location.href = `/auto_login?token=${encodeURIComponent(token)}`
        } else if (url.includes("/auth/")) {
          // Phase 2a 互換経路 (= AssetLinks intent-filter 経由のフォールバック、Phase 3 動作確認後に削除予定)
          const parsed = new URL(url)
          window.location.href = parsed.pathname + parsed.search
        }
      } catch (error) {
        console.error("[Capacitor] appUrlOpen handler error:", error)
      }
    })
  } else {
    console.warn("[Capacitor] App plugin not registered, deep link unsupported (= cap sync 不足の可能性)")
  }
}
