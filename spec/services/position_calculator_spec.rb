require 'spec_helper'

RSpec.describe Teyca::Services::PositionCalculator do
  let(:bronze) { double(discount: 0,  cashback: 5) }
  let(:silver) { double(discount: 5,  cashback: 5) }
  let(:gold)   { double(discount: 15, cashback: 0) }

  def calc(input:, template:, product: nil)
    modifier = Teyca::Services::Modifiers.for(product)
    described_class.new(input: input, template: template, modifier: modifier).call
  end

  describe 'Bronze without modifiers' do
    let(:result) do
      calc(input: { id: 1, price: 100, quantity: 3 }, template: bronze)
    end

    it 'has no discount' do
      expect(result.discount_value).to eq(0)
      expect(result.discount_percent).to eq(0)
    end

    it 'computes cashback on the full subtotal' do
      # 300 * 5% = 15
      expect(result.cashback_percent).to eq(5)
      expect(result.cashback_value).to eq(15)
    end

    it 'payable equals subtotal' do
      expect(result.subtotal).to eq(300)
      expect(result.payable).to eq(300)
    end

    it 'is loyalty eligible' do
      expect(result.loyalty_eligible?).to be true
    end
  end

  describe 'Gold without modifiers' do
    let(:result) do
      calc(input: { id: 1, price: 200, quantity: 2 }, template: gold)
    end

    it 'applies 15% discount and zero cashback' do
      # 400 * 15% = 60 discount, payable = 340, cashback = 0
      expect(result.discount_percent).to eq(15)
      expect(result.discount_value).to eq(60)
      expect(result.payable).to eq(340)
      expect(result.cashback_value).to eq(0)
    end
  end

  describe 'Silver with extra discount modifier' do
    let(:product) { double(type: 'discount', value: '10') }
    let(:result) do
      calc(input: { id: 3, price: 100, quantity: 1 }, template: silver, product: product)
    end

    it 'sums template + product discount' do
      expect(result.discount_percent).to eq(15)
      expect(result.discount_value).to eq(15)
      expect(result.payable).to eq(85)
    end

    it 'computes cashback on payable' do
      # 85 * 5% = 4.25
      expect(result.cashback_value).to eq(4.25)
    end
  end

  describe 'Bronze with increased_cashback modifier' do
    let(:product) { double(type: 'increased_cashback', value: '10') }
    let(:result) do
      calc(input: { id: 2, price: 50, quantity: 2 }, template: bronze, product: product)
    end

    it 'sums template + product cashback' do
      # 100 * (5+10)% = 15
      expect(result.cashback_percent).to eq(15)
      expect(result.cashback_value).to eq(15)
    end

    it 'has no discount' do
      expect(result.discount_value).to eq(0)
    end
  end

  describe 'Any template with noloyalty product' do
    let(:product) { double(type: 'noloyalty', value: nil) }
    let(:result) do
      calc(input: { id: 4, price: 150, quantity: 2 }, template: gold, product: product)
    end

    it 'has zero discount and cashback' do
      expect(result.discount_value).to eq(0)
      expect(result.cashback_value).to eq(0)
    end

    it 'is not loyalty eligible' do
      expect(result.loyalty_eligible?).to be false
    end

    it 'payable equals raw subtotal' do
      expect(result.payable).to eq(300)
    end
  end

  describe 'serialization' do
    let(:product) { double(type: 'discount', value: '15') }
    let(:result) do
      calc(input: { id: 3, price: 40, quantity: 1 }, template: silver, product: product)
    end

    it 'exposes the full position payload' do
      payload = result.to_h
      expect(payload).to include(
        id: 3,
        price: 40,
        quantity: 1,
        type: 'discount',
        value: '15',
        discount_percent: 20,
        discount_value: 8
      )
      expect(payload[:description]).to match(/Дополнительная скидка/)
    end
  end
end
