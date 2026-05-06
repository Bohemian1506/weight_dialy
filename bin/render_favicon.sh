#!/usr/bin/env bash
# Favicon 各サイズ PNG 生成スクリプト。public/favicons/source.html を puppeteer で
# 各サイズに切り出し、public/ 直下に配置する。
#
# 使い方: bin/render_favicon.sh
# 出力:
#   - public/favicon-16x16.png  (= 16x16、ミニ版「+」のみ)
#   - public/favicon-32x32.png  (= 32x32、ドット無し版)
#   - public/favicon-64x64.png  (= 64x64、フル版)
#   - public/apple-touch-icon.png (= 180x180、iOS Home Screen)
#   - public/icon.png            (= 512x512 上書き、PWA / 一般 favicon)
#
# 仕組み:
#   - HTML プロトタイプ内の .fav.size-{16|32|64|180|512} 要素を element.screenshot で個別 capture
#   - 最初の matching element (= グリッド内の cell) を使う (= browser-mock / home-row 由来は除外)
#   - deviceScaleFactor: 1 (= 純粋なピクセルサイズ、retina スケールアップは不要)
#
# 再生成タイミング: public/favicons/source.html を変更したら都度再実行 + commit。
# CI には組み込まない (= Chromium ダウンロードコスト不要、手元再生成で十分)。

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML_PATH="$REPO_ROOT/public/favicons/source.html"

if [ ! -f "$HTML_PATH" ]; then
  echo "❌ $HTML_PATH not found" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "→ Installing puppeteer in temp dir ($WORK_DIR)..."
cd "$WORK_DIR"
npm init -y > /dev/null
npm install --no-save --no-audit --no-fund puppeteer > /dev/null 2>&1

cat > render.js <<'JSEOF'
const puppeteer = require('puppeteer');
const path = require('path');

const HTML_PATH = process.argv[2];
const REPO_ROOT = process.argv[3];

const SIZES = [
  { selector: '.fav.size-16',  out: 'favicon-16x16.png',     label: '16x16' },
  { selector: '.fav.size-32',  out: 'favicon-32x32.png',     label: '32x32' },
  { selector: '.fav.size-64',  out: 'favicon-64x64.png',     label: '64x64' },
  { selector: '.fav.size-180', out: 'apple-touch-icon.png',  label: '180x180' },
  { selector: '.fav.size-512', out: 'icon.png',              label: '512x512' },
];

(async () => {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 2400, height: 3200, deviceScaleFactor: 1 });
  await page.goto(`file://${path.resolve(HTML_PATH)}`, {
    waitUntil: 'networkidle0',
    timeout: 30000,
  });
  await page.evaluateHandle('document.fonts.ready');

  for (const { selector, out, label } of SIZES) {
    // 最初の matching element (= グリッド内のもの、browser-mock / home-row は後ろ) を使用
    const el = await page.$(selector);
    if (!el) {
      console.error(`✗ ${selector} not found`);
      continue;
    }
    const outPath = path.join(REPO_ROOT, 'public', out);
    await el.screenshot({ path: outPath, omitBackground: false });
    console.log(`✓ ${label} → public/${out}`);
  }

  await browser.close();
})();
JSEOF

echo "→ Rendering favicons from $HTML_PATH..."
node render.js "$HTML_PATH" "$REPO_ROOT"
echo ""
echo "✓ All favicons generated:"
ls -lh "$REPO_ROOT/public/favicon-16x16.png" "$REPO_ROOT/public/favicon-32x32.png" "$REPO_ROOT/public/favicon-64x64.png" "$REPO_ROOT/public/apple-touch-icon.png" "$REPO_ROOT/public/icon.png" 2>&1
