require 'spec_helper'

RSpec.describe Teyca::Services::Modifiers do
  describe '.for' do
    it 'returns NullModifier when product is nil' do
      expect(described_class.for(nil)).to be_a(Teyca::Services::Modifiers::NullModifier)
    end

    it 'returns DiscountModifier for discount type' do
      product = double(type: 'discount', value: '10')
      expect(described_class.for(product)).to be_a(Teyca::Services::Modifiers::DiscountModifier)
    end

    it 'returns IncreasedCashbackModifier for increased_cashback type' do
      product = double(type: 'increased_cashback', value: '7')
      expect(described_class.for(product)).to be_a(Teyca::Services::Modifiers::IncreasedCashbackModifier)
    end

    it 'returns NoLoyaltyModifier for noloyalty type' do
      product = double(type: 'noloyalty', value: nil)
      expect(described_class.for(product)).to be_a(Teyca::Services::Modifiers::NoLoyaltyModifier)
    end

    it 'returns NullModifier for an unknown type' do
      product = double(type: 'unknown', value: '1')
      expect(described_class.for(product)).to be_a(Teyca::Services::Modifiers::NullModifier)
    end
  end

  describe Teyca::Services::Modifiers::NullModifier do
    subject(:mod) { described_class.new }

    it 'passes discount through' do
      expect(mod.discount_percent(15)).to eq(15)
    end

    it 'passes cashback through' do
      expect(mod.cashback_percent(5)).to eq(5)
    end

    it 'is loyalty eligible' do
      expect(mod.loyalty_eligible?).to be true
    end
  end

  describe Teyca::Services::Modifiers::DiscountModifier do
    let(:product) { double(type: 'discount', value: '10') }
    subject(:mod) { described_class.new(product) }

    it 'adds extra discount to template discount' do
      expect(mod.discount_percent(5)).to eq(15)
    end

    it 'leaves cashback unchanged' do
      expect(mod.cashback_percent(5)).to eq(5)
    end

    it 'is loyalty eligible' do
      expect(mod.loyalty_eligible?).to be true
    end

    it 'exposes its type and value' do
      expect(mod.type).to eq('discount')
      expect(mod.value).to eq('10')
    end
  end

  describe Teyca::Services::Modifiers::IncreasedCashbackModifier do
    let(:product) { double(type: 'increased_cashback', value: '7') }
    subject(:mod) { described_class.new(product) }

    it 'leaves discount unchanged' do
      expect(mod.discount_percent(15)).to eq(15)
    end

    it 'adds extra cashback to template cashback' do
      expect(mod.cashback_percent(5)).to eq(12)
    end

    it 'is loyalty eligible' do
      expect(mod.loyalty_eligible?).to be true
    end
  end

  describe Teyca::Services::Modifiers::NoLoyaltyModifier do
    let(:product) { double(type: 'noloyalty', value: nil) }
    subject(:mod) { described_class.new(product) }

    it 'zeroes discount regardless of template' do
      expect(mod.discount_percent(15)).to eq(0)
    end

    it 'zeroes cashback regardless of template' do
      expect(mod.cashback_percent(5)).to eq(0)
    end

    it 'is not loyalty eligible' do
      expect(mod.loyalty_eligible?).to be false
    end
  end
end
