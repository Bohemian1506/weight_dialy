require "rails_helper"

RSpec.describe PlatformDetectorService, type: :request do
  # from_request は request オブジェクトの user_agent を参照するため、
  # request spec 内で GET / を呼んで request を実体として渡す代わりに、
  # 軽量な double でインターフェースを満たす。
  def detector_for(ua_string)
    fake_request = instance_double(ActionDispatch::Request, user_agent: ua_string)
    PlatformDetectorService.from_request(fake_request)
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
end
