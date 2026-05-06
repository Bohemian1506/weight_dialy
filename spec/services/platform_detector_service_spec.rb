require "rails_helper"

RSpec.describe PlatformDetectorService, type: :request do
  # from_request / web_android? は request オブジェクトの user_agent を参照するため、
  # 軽量な double でインターフェースを満たす。
  def detector_for(ua_string)
    fake_request = instance_double(ActionDispatch::Request, user_agent: ua_string)
    PlatformDetectorService.from_request(fake_request)
  end

  def web_android_for(ua_string)
    fake_request = instance_double(ActionDispatch::Request, user_agent: ua_string)
    PlatformDetectorService.web_android?(fake_request)
  end

  describe ".from_request" do
    context "iOS デバイス" do
      it "iPhone UA を :ios と判定する" do
        ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        expect(detector_for(ua)).to eq(:ios)
      end

      it "iPad UA を :ios と判定する" do
        ua = "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        expect(detector_for(ua)).to eq(:ios)
      end

      it "iPod UA を :ios と判定する" do
        ua = "Mozilla/5.0 (iPod touch; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15"
        expect(detector_for(ua)).to eq(:ios)
      end
    end

    context "Android デバイス" do
      it "Android UA を :android と判定する" do
        ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/120.0.0.0"
        expect(detector_for(ua)).to eq(:android)
      end
    end

    context "PC ブラウザ" do
      it "Chrome on Mac の UA を :other と判定する" do
        ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
        expect(detector_for(ua)).to eq(:other)
      end
    end

    context "UA が空またはnil" do
      it "nil を :other と判定する" do
        expect(detector_for(nil)).to eq(:other)
      end

      it "空文字を :other と判定する" do
        expect(detector_for("")).to eq(:other)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # .web_android? (Issue #184)
  # Capacitor アプリ (WeightDialyCapacitor を UA に含む) は false、
  # 純粋な Android Web ブラウザは true。
  # ---------------------------------------------------------------------------
  describe ".web_android?" do
    context "Android Web ブラウザ (Capacitor なし)" do
      it "Android Chrome UA を true と判定する" do
        ua = "Mozilla/5.0 (Linux; Android 13; SM-S908U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
        expect(web_android_for(ua)).to be(true)
      end
    end

    context "Android Capacitor アプリ (WeightDialyCapacitor を UA に含む)" do
      it "Capacitor UA を false と判定する" do
        ua = "Mozilla/5.0 (Linux; Android 13; SM-S908U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 WeightDialyCapacitor"
        expect(web_android_for(ua)).to be(false)
      end
    end

    context "iOS デバイス" do
      it "iPhone UA を false と判定する" do
        ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        expect(web_android_for(ua)).to be(false)
      end
    end

    context "PC ブラウザ" do
      it "Mac Chrome UA を false と判定する" do
        ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
        expect(web_android_for(ua)).to be(false)
      end
    end
  end
end
