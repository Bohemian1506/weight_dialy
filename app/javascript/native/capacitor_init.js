// Capacitor アプリ初期化処理 (= 学び 19 / Phase 2a 由来)
//
// 目的: OAuth Custom Tabs から callback で Capacitor アプリに帰還した時、
//       callback URL (= /auth/google_oauth2/callback?code=...) を Capacitor の WebView 内で開いて
//       Rails のセッションを Capacitor アプリ内で確立する。
//
// 仕組み:
// 1. AndroidManifest に <intent-filter> で weight-dialy.onrender.com/auth/* を Capacitor アプリで受信
// 2. ユーザーが Custom Tabs で OAuth 完了 → Android が「アプリで開く?」ダイアログ表示
// 3. ユーザーが Capacitor アプリ選択 → appUrlOpen イベント発火
// 4. ハンドラーで callback URL を WebView 内に navigate (= 同じ session cookie で動く)
//
// Phase 2a (本実装): 「アプリで開く?」ダイアログあり、AppLinks verify なし
// Phase 2b (= v1.0 後半): autoVerify="true" + AssetLinks 配信で seamless 化

if (typeof window.Capacitor !== "undefined" && window.Capacitor.isNativePlatform?.()) {
  const App = window.Capacitor.Plugins.App
  if (App && typeof App.addListener === "function") {
    App.addListener("appUrlOpen", (data) => {
      // OAuth callback URL には ?code=... が含まれるため console.log は使わない (= Logcat / DevTools 経由で露出する、code 自体は使い捨てだが本番ログ汚染を避ける)。
      // デバッグ時のみ DevTools の Verbose レベルで観測可能。
      console.debug("[Capacitor] appUrlOpen received")
      if (data?.url?.includes("/auth/")) {
        // server.url で本番 Web を WebView 表示している前提、callback URL の path + query だけ抽出して navigate
        try {
          const url = new URL(data.url)
          window.location.href = url.pathname + url.search
        } catch (error) {
          console.error("[Capacitor] appUrlOpen URL parse error:", error)
        }
      }
    })
  } else {
    console.warn("[Capacitor] App plugin not registered, deep link unsupported (= cap sync 不足の可能性)")
  }
}
