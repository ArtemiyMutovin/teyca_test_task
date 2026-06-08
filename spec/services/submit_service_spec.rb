require 'spec_helper'

RSpec.describe Teyca::Services::SubmitService do
  def calculate(user_id, positions)
    Teyca::Services::OperationCalculator.new(user_id: user_id, positions: positions).call
  end

  def user_payload_from(user)
    { id: user.id, template_id: user.template_id, name: user.name, bonus: user.bonus.to_s }
  end

  let(:user) { Teyca::Models::User[1] }
  let(:positions) do
    [
      { id: 1, price: 100, quantity: 3 },
      { id: 2, price: 50,  quantity: 2 },
      { id: 3, price: 40,  quantity: 1 },
      { id: 4, price: 150, quantity: 2 }
    ]
  end

  let(:calc_response) { calculate(user.id, positions) }
  let(:operation)     { Teyca::Models::Operation[calc_response[:operation_id]] }

  def submit(write_off)
    described_class.new(
      user: user_payload_from(user),
      operation_id: operation.id,
      write_off: write_off
    ).call
  end

  describe 'partial write off' do
    let(:response) { submit(150) }

    it 'returns ok status with message' do
      expect(response[:status]).to eq('ok')
      expect(response[:message]).to be_a(String)
    end

    it 'subtracts write-off from sum to pay' do
      # original summ = 734, write_off = 150 -> 584
      expect(response[:operation][:to_pay]).to eq(584)
    end

    it 'recalculates cashback proportionally to non-spent loyalty payable' do
      # allowed_write_off = 434, original cashback = 31.7
      # new cashback = 31.7 * (434 - 150) / 434 ~= 20.74
      expect(response[:operation][:cashback]).to be_within(0.05).of(20.74)
    end

    it 'records write_off and marks operation done' do
      submit(150)
      operation.refresh
      expect(operation.write_off.to_f).to eq(150)
      expect(operation.done?).to be true
    end

    it 'debits user bonus by write_off and credits new cashback' do
      original_bonus = user.bonus.to_f
      response = submit(150)
      user.refresh
      expect(user.bonus.to_f).to be_within(0.05).of(original_bonus - 150 + response[:operation][:cashback])
    end
  end

  describe 'full write off of allowed amount' do
    let(:response) { submit(434) }

    it 'leaves only the noloyalty portion to pay' do
      # noloyalty total = 300
      expect(response[:operation][:to_pay]).to eq(300)
    end

    it 'zeroes cashback' do
      expect(response[:operation][:cashback]).to eq(0)
    end
  end

  describe 'zero write off' do
    let(:response) { submit(0) }

    it 'keeps original totals' do
      expect(response[:operation][:to_pay]).to eq(734)
      expect(response[:operation][:cashback]).to be_within(0.01).of(31.7)
    end

    it 'still marks the operation done' do
      submit(0)
      operation.refresh
      expect(operation.done?).to be true
    end
  end

  describe 'validations' do
    it 'rejects write_off exceeding allowed_write_off' do
      expect { submit(500) }.to raise_error(Teyca::Services::SubmitService::WriteOffExceedsAllowed)
    end

    it 'rejects write_off exceeding user bonus' do
      Teyca::Models::User.where(id: user.id).update(bonus: 100)
      user.refresh
      expect { submit(150) }.to raise_error(Teyca::Services::SubmitService::WriteOffExceedsBonus)
    end

    it 'rejects negative write_off' do
      expect { submit(-1) }.to raise_error(Teyca::Services::SubmitService::InvalidWriteOff)
    end

    it 'rejects already completed operations' do
      submit(0)
      expect { submit(0) }.to raise_error(Teyca::Services::SubmitService::OperationAlreadyDone)
    end

    it 'rejects unknown operation id' do
      svc = described_class.new(user: user_payload_from(user), operation_id: 999_999, write_off: 0)
      expect { svc.call }.to raise_error(Teyca::Services::SubmitService::OperationNotFound)
    end

    it 'rejects submitting another user operation' do
      stranger = Teyca::Models::User[2]
      op = Teyca::Services::OperationCalculator.new(
        user_id: user.id, positions: [{ id: 1, price: 100, quantity: 1 }]
      ).call
      svc = described_class.new(
        user: user_payload_from(stranger),
        operation_id: op[:operation_id],
        write_off: 0
      )
      expect { svc.call }.to raise_error(Teyca::Services::SubmitService::OperationForbidden)
    end
  end
end
