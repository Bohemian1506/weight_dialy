require "rails_helper"

RSpec.describe CalorieEquivalentService do
  # 全テストで seed: を明示注入して確定的な挙動にする。
  # グローバル乱数状態 (Kernel#srand) とは独立した Random.new を使うため
  # srand リセットは不要。

  # 新アルゴリズム (shuffle + 再抽選) での seed 別採用食品:
  #   - Foods::ALL.shuffle(random: rng) で並び順を確定し、1 <= count <= max_count(5) を
  #     満たす最初の食品を採用する。以下は today_kcal=1000, max_count=5 での結果。
  #   seed=0   → おにぎり   180 kcal (count=5)
  #   seed=1   → おにぎり   180 kcal (count=5)
  #   seed=2   → 大福       170 kcal (count=5)
  #   seed=5   → 大福       170 kcal (count=5)
  #   seed=6   → どら焼き   200 kcal (count=5)
  #   seed=42  → 大福       170 kcal (count=5)
  #   seed=100 → どら焼き   200 kcal (count=5)
  #   seed=123 → アイス     200 kcal (count=5)
  #   seed=999 → 唐揚げ 3 個 250 kcal (count=4)

  describe ".call" do
    # ─────────────────────────────────────────────────
    # nil 返却: today_kcal < 90 (最小食品 kcal 未満)
    # ─────────────────────────────────────────────────
    context "today_kcal = 0 のとき" do
      it "nil を返す" do
        expect(described_class.call(0, seed: 0)).to be_nil
      end
    end

    context "today_kcal = 50 のとき" do
      it "nil を返す" do
        expect(described_class.call(50, seed: 0)).to be_nil
      end
    end

    context "today_kcal = 89 のとき (最小食品 kcal の 1 未満)" do
      it "nil を返す" do
        expect(described_class.call(89, seed: 0)).to be_nil
      end
    end

    # ─────────────────────────────────────────────────
    # 境界値: today_kcal = 90 (最小食品 kcal と同値)
    # ─────────────────────────────────────────────────
    context "today_kcal = 90 かつ seed=2 (shuffle後の最初の 90 kcal 食品: バナナ) のとき" do
      subject(:result) { described_class.call(90, seed: 2) }

      it "nil ではない" do
        expect(result).not_to be_nil
      end

      it "count が 1 である (90 / 90 = 1)" do
        expect(result[:count]).to eq(1)
      end

      it "name が「バナナ」である" do
        expect(result[:name]).to eq("バナナ")
      end
    end

    context "today_kcal = 90 かつ seed=42 (shuffle後の最初の 90 kcal 食品: カップヨーグルト) のとき" do
      subject(:result) { described_class.call(90, seed: 42) }

      it "nil ではない (再抽選でカップヨーグルトが見つかる)" do
        expect(result).not_to be_nil
      end

      it "count が 1 である (90 / 90 = 1)" do
        expect(result[:count]).to eq(1)
      end

      it "name が「カップヨーグルト」である" do
        expect(result[:name]).to eq("カップヨーグルト")
      end
    end

    # ─────────────────────────────────────────────────
    # 返却値の構造検証
    # ─────────────────────────────────────────────────
    context "today_kcal = 200 かつ seed=0 (shuffle後の最初の適合食品: おにぎり 180 kcal) のとき" do
      subject(:result) { described_class.call(200, seed: 0) }

      it "nil ではない" do
        expect(result).not_to be_nil
      end

      it ":emoji キーを持つ" do
        expect(result).to have_key(:emoji)
      end

      it ":name キーを持つ" do
        expect(result).to have_key(:name)
      end

      it ":unit キーを持つ" do
        expect(result).to have_key(:unit)
      end

      it ":count キーを持つ" do
        expect(result).to have_key(:count)
      end

      it "count が Integer である" do
        expect(result[:count]).to be_a(Integer)
      end

      it "count が 1 以上である" do
        expect(result[:count]).to be >= 1
      end

      it "count が 1 である (200 / 180 = 1)" do
        expect(result[:count]).to eq(1)
      end

      it "name が「おにぎり」である" do
        expect(result[:name]).to eq("おにぎり")
      end

      it "emoji が「🍙」である" do
        expect(result[:emoji]).to eq("🍙")
      end

      it "unit が「個」である" do
        expect(result[:unit]).to eq("個")
      end
    end

    context "today_kcal = 200 かつ seed=5 (カフェラテ 150 kcal が選ばれる) のとき" do
      subject(:result) { described_class.call(200, seed: 5) }

      it "count が 1 である (200 / 150 = 1)" do
        expect(result[:count]).to eq(1)
      end

      it "unit が「杯」である" do
        expect(result[:unit]).to eq("杯")
      end
    end

    context "today_kcal = 200 かつ seed=6 (カップヨーグルト 90 kcal が選ばれる) のとき" do
      subject(:result) { described_class.call(200, seed: 6) }

      it "count が 2 である (200 / 90 = 2)" do
        expect(result[:count]).to eq(2)
      end

      it "unit が「個」である" do
        expect(result[:unit]).to eq("個")
      end
    end

    context "today_kcal = 200 かつ seed=7 (カップヨーグルト 90 kcal が選ばれる) のとき" do
      subject(:result) { described_class.call(200, seed: 7) }

      it "count が 2 である (200 / 90 = 2)" do
        expect(result[:count]).to eq(2)
      end

      it "unit が「個」である" do
        expect(result[:unit]).to eq("個")
      end
    end

    # ─────────────────────────────────────────────────
    # today_kcal = 1000 (count 上限キャップの動作確認)
    # ─────────────────────────────────────────────────
    context "today_kcal = 1000 かつ seed=42 (大福 170 kcal, count=5) のとき" do
      subject(:result) { described_class.call(1000, seed: 42) }

      it "count が 5 である (1000 / 170 = 5, max_count=5 以内)" do
        expect(result[:count]).to eq(5)
      end

      it "unit が「個」である" do
        expect(result[:unit]).to eq("個")
      end
    end

    context "today_kcal = 1000 かつ seed=123 (アイス 200 kcal, count=5) のとき" do
      subject(:result) { described_class.call(1000, seed: 123) }

      it "count が 5 である (1000 / 200 = 5)" do
        expect(result[:count]).to eq(5)
      end
    end

    context "today_kcal = 1000 かつ seed=5 (大福 170 kcal, count=5: 旧バナナ count=11 は上限超え) のとき" do
      subject(:result) { described_class.call(1000, seed: 5) }

      it "count が max_count (5) 以下である" do
        expect(result[:count]).to be <= 5
      end

      it "count が 5 である (大福 170 kcal で 1000 / 170 = 5)" do
        expect(result[:count]).to eq(5)
      end
    end

    context "today_kcal = 1000 かつ seed=999 (唐揚げ 3 個 250 kcal, count=4) のとき" do
      subject(:result) { described_class.call(1000, seed: 999) }

      it "count が 4 である (1000 / 250 = 4)" do
        expect(result[:count]).to eq(4)
      end

      it "unit が「皿」である" do
        expect(result[:unit]).to eq("皿")
      end
    end

    # ─────────────────────────────────────────────────
    # count 上限キャップ: max_count を超えないこと
    # ─────────────────────────────────────────────────
    context "today_kcal = 5000 (全食品で count > 5 になる) のとき" do
      subject(:result) { described_class.call(5000, seed: 0) }

      it "nil ではない (フォールバックで最大 kcal 食品が返る)" do
        expect(result).not_to be_nil
      end

      it "count が max_count (5) 以下である" do
        expect(result[:count]).to be <= 5
      end

      it "フォールバックで唐揚げ 3 個 (最大 kcal 250) が返る" do
        expect(result[:name]).to eq("唐揚げ 3 個")
      end

      it "count が 5 にキャップされている (5000 / 250 = 20 → cap)" do
        expect(result[:count]).to eq(5)
      end
    end

    context "max_count: 3 を指定したとき (today_kcal = 1000, seed=0)" do
      # seed=0 では全食品で count > 3 → フォールバックで唐揚げ 3 個 (250 kcal) + cap
      subject(:result) { described_class.call(1000, seed: 0, max_count: 3) }

      it "count が 3 以下である" do
        expect(result[:count]).to be <= 3
      end

      it "count が 3 にキャップされている (1000 / 250 = 4 → cap 3)" do
        expect(result[:count]).to eq(3)
      end

      it "フォールバックで唐揚げ 3 個が返る" do
        expect(result[:name]).to eq("唐揚げ 3 個")
      end
    end

    # ─────────────────────────────────────────────────
    # シード固定の確定性 (同一 seed → 毎回同じ結果)
    # ─────────────────────────────────────────────────
    context "確定性: 同一 seed で複数回呼んでも同じ結果を返す" do
      it "seed=42, kcal=1000 で 2 回呼んでも同じ Hash を返す" do
        first  = described_class.call(1000, seed: 42)
        second = described_class.call(1000, seed: 42)
        expect(first).to eq(second)
      end

      it "seed=0, kcal=500 で 2 回呼んでも同じ Hash を返す" do
        first  = described_class.call(500, seed: 0)
        second = described_class.call(500, seed: 0)
        expect(first).to eq(second)
      end
    end

    # ─────────────────────────────────────────────────
    # シード別に異なる食品が選ばれること
    # ─────────────────────────────────────────────────
    context "seed の違いで異なる食品が選ばれる" do
      it "seed=0 (おにぎり) と seed=42 (大福) では name が異なる" do
        result_0  = described_class.call(1000, seed: 0)
        result_42 = described_class.call(1000, seed: 42)
        expect(result_0[:name]).not_to eq(result_42[:name])
      end

      it "seed=100 (どら焼き) と seed=999 (唐揚げ 3 個) では name が異なる" do
        result_100 = described_class.call(1000, seed: 100)
        result_999 = described_class.call(1000, seed: 999)
        expect(result_100[:name]).not_to eq(result_999[:name])
      end
    end

    # ─────────────────────────────────────────────────
    # unit の取り得る値 (実装の Item 定義参照)
    # ─────────────────────────────────────────────────
    context "unit の値" do
      valid_units = %w[個 本 枚 杯 皿]

      # seed=0(おにぎり→個), seed=5(大福→個), seed=6(どら焼き→個), seed=7(大福→個),
      # seed=42(大福→個), seed=999(唐揚げ→皿)
      {
        0   => "個",  # おにぎり
        5   => "個",  # 大福
        6   => "個",  # どら焼き
        7   => "個",  # 大福
        999 => "皿"  # 唐揚げ 3 個
      }.each do |seed, expected_unit|
        it "seed=#{seed} のとき unit が「#{expected_unit}」である" do
          result = described_class.call(1000, seed: seed)
          expect(result[:unit]).to eq(expected_unit)
        end
      end

      it "seed=100 のとき unit が valid_units のいずれかである" do
        result = described_class.call(500, seed: 100)
        expect(valid_units).to include(result[:unit])
      end
    end

    # ─────────────────────────────────────────────────
    # グローバル乱数状態への副作用なし
    # ─────────────────────────────────────────────────
    context "グローバル乱数状態への副作用" do
      it "呼び出し後も Kernel#rand の系列が変わらない (Random.new 使用のため)" do
        srand(12_345)
        expected_next = rand
        srand(12_345)
        described_class.call(500, seed: 99)
        expect(rand).to eq(expected_next)
      end
    end
  end
end
