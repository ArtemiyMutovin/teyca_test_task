require 'spec_helper'

RSpec.describe Teyca::Services::OperationCalculator do
  def fetch_user(id) = Teyca::Models::User[id]

  def call(user_id, positions)
    described_class.new(user_id: user_id, positions: positions).call
  end

  describe 'Bronze user (id=1) buying mixed cart from Postman example' do
    # positions: 1x?x3@100, 2(milk +10% cashback)x2@50, 3(bread +15% discount)x1@40, 4(noloyalty)x2@150
    let(:positions) do
      [
        { id: 1, price: 100, quantity: 3 },
        { id: 2, price: 50,  quantity: 2 },
        { id: 3, price: 40,  quantity: 1 },
        { id: 4, price: 150, quantity: 2 }
      ]
    end

    let(:response) { call(1, positions) }

    it 'returns ok status' do
      expect(response[:status]).to eq('ok')
    end

    it 'returns user info' do
      expect(response[:user]).to include(id: 1, name: 'Иван', template_id: 1)
    end

    it 'persists an operation and returns its id' do
      expect(response[:operation_id]).to be_an(Integer)
      expect(Teyca::Models::Operation[response[:operation_id]]).not_to be_nil
    end

    it 'computes summ as sum of payables' do
      # bronze discount=0, so payable equals subtotal everywhere.
      # subtotals: 300 + 100 + 34 (40 - 15%) + 300 = 734
      expect(response[:summ]).to eq(734)
    end

    it 'computes total discount and percent' do
      # only position 3 has a discount: 40 * 15% = 6
      expect(response[:discount_info][:total_discount]).to eq(6)
      # effective discount = 6 / 740 * 100
      expect(response[:discount_info][:total_discount_percent]).to be_within(0.01).of(0.81)
    end

    it 'computes cashback only on loyalty-eligible payables' do
      # eligible payables: 300 + 100 + 34 = 434 (position 4 is noloyalty)
      # cashback: 300*5% + 100*15% + 34*5% = 15 + 15 + 1.7 = 31.7
      expect(response[:bonus_info][:will_be_credited]).to be_within(0.01).of(31.7)
    end

    it 'allowed_write_off equals sum of loyalty-eligible payables' do
      expect(response[:bonus_info][:allowed_write_off]).to eq(434)
    end

    it 'returns user bonus balance' do
      expect(response[:bonus_info][:balance].to_f).to eq(10_000.0)
    end

    it 'returns one entry per position' do
      expect(response[:positions].size).to eq(4)
      expect(response[:positions].map { _1[:id] }).to eq([1, 2, 3, 4])
    end
  end

  describe 'Gold user (id=3) without modifiers' do
    let(:response) { call(3, [{ id: 99, price: 200, quantity: 1 }]) }

    it 'applies template discount and zero cashback' do
      expect(response[:summ]).to eq(170) # 200 - 15%
      expect(response[:discount_info][:total_discount]).to eq(30)
      expect(response[:bonus_info][:will_be_credited]).to eq(0)
    end
  end

  describe 'when user is missing' do
    it 'raises a domain error' do
      expect { call(999_999, [{ id: 1, price: 10, quantity: 1 }]) }
        .to raise_error(Teyca::Services::OperationCalculator::UserNotFound)
    end
  end

  describe 'persisted operation columns' do
    let(:response) do
      call(2, [
        { id: 1, price: 100, quantity: 1 },
        { id: 4, price: 100, quantity: 1 }
      ])
    end

    it 'stores aggregates on the row' do
      op = Teyca::Models::Operation[response[:operation_id]]
      # Silver: discount 5%, cashback 5%.
      # pos1: subtotal 100, discount 5, payable 95, cashback 4.75
      # pos4: noloyalty -> discount 0, cashback 0, payable 100
      expect(op.user_id).to eq(2)
      expect(op.check_summ.to_f).to eq(195.0)
      expect(op.discount.to_f).to eq(5.0)
      expect(op.cashback.to_f).to eq(4.75)
      expect(op.allowed_write_off.to_f).to eq(95.0)
      expect(op.done?).to be false
    end
  end
end
