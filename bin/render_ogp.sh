#!/usr/bin/env bash
# OGP 画像生成スクリプト。public/ogp.html を 1200x630 の PNG に変換する。
#
# 使い方: bin/render_ogp.sh
# 出力: public/ogp.png
#
# 仕組み:
#   - puppeteer (= headless Chrome) を一時ディレクトリにインストール (= リポジトリ汚染回避)
#   - public/ogp.html を file:// で開き、.ogp 要素を 2x deviceScaleFactor で screenshot
#   - .ogp 要素 1200x630 を撮影、最終 PNG は 2400x1260 (= retina クオリティ)
#
# 初回実行時は puppeteer が Chromium をダウンロードする (~150MB、数分)。
# Chromium キャッシュは ~/.cache/puppeteer/ に残る (= 2 回目以降は数秒)。
#
# 再生成タイミング: public/ogp.html を変更したら都度再実行 + commit。
# CI には組み込まない (= Chromium ダウンロードコストが釣り合わない、手元再生成で十分)。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML_PATH="$REPO_ROOT/public/ogp.html"
PNG_PATH="$REPO_ROOT/public/ogp.png"

if [ ! -f "$HTML_PATH" ]; then
  echo "❌ $HTML_PATH not found" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "→ Installing puppeteer in temp dir ($WORK_DIR)..."
cd "$WORK_DIR"
npm init -y > /dev/null
# --no-save: package.json に書かない (= 一時インストール)
npm install --no-save --no-audit --no-fund puppeteer > /dev/null 2>&1

cat > render.js <<'JSEOF'
const puppeteer = require('puppeteer');
const path = require('path');

const HTML_PATH = process.argv[2];
const PNG_PATH = process.argv[3];

(async () => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  // body の padding 24px*2 + .ogp の box-shadow 14px はみ出し分を含めた viewport
  await page.setViewport({ width: 1300, height: 720, deviceScaleFactor: 2 });
  await page.goto(`file://${path.resolve(HTML_PATH)}`, {
    waitUntil: 'networkidle0',
    timeout: 30000,
  });
  // フォント読み込み完了を確実に待つ
  await page.evaluateHandle('document.fonts.ready');

  // .ogp 要素のみ撮影 (= body 背景や padding を除外、box-shadow は子要素ではみ出すため別調整不要)
  const ogp = await page.$('.ogp');
  if (!ogp) throw new Error('.ogp element not found');
  await ogp.screenshot({ path: PNG_PATH, omitBackground: false });

  await browser.close();
})();
JSEOF

echo "→ Rendering $HTML_PATH → $PNG_PATH"
node render.js "$HTML_PATH" "$PNG_PATH"
echo "✓ Generated $PNG_PATH"
ls -lh "$PNG_PATH"
