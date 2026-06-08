require 'spec_helper'

RSpec.describe Teyca::Services::RequestValidator do
  describe '.operation!' do
    let(:valid) { { user_id: 1, positions: [{ id: 1, price: 100, quantity: 2 }] } }

    it 'accepts a valid payload' do
      expect { described_class.operation!(valid) }.not_to raise_error
    end

    it 'rejects missing user_id' do
      expect { described_class.operation!(positions: valid[:positions]) }
        .to raise_error(described_class::InvalidRequest, /user_id/)
    end

    it 'rejects empty positions' do
      expect { described_class.operation!(user_id: 1, positions: []) }
        .to raise_error(described_class::InvalidRequest, /positions/)
    end

    it 'rejects non-array positions' do
      expect { described_class.operation!(user_id: 1, positions: 'oops') }
        .to raise_error(described_class::InvalidRequest)
    end

    it 'rejects zero quantity' do
      payload = { user_id: 1, positions: [{ id: 1, price: 100, quantity: 0 }] }
      expect { described_class.operation!(payload) }
        .to raise_error(described_class::InvalidRequest, /quantity/)
    end

    it 'rejects negative price' do
      payload = { user_id: 1, positions: [{ id: 1, price: -1, quantity: 1 }] }
      expect { described_class.operation!(payload) }
        .to raise_error(described_class::InvalidRequest, /price/)
    end
  end

  describe '.submit!' do
    let(:valid) { { user: { id: 1 }, operation_id: 1, write_off: 0 } }

    it 'accepts a valid payload' do
      expect { described_class.submit!(valid) }.not_to raise_error
    end

    it 'rejects missing user' do
      expect { described_class.submit!(operation_id: 1, write_off: 0) }
        .to raise_error(described_class::InvalidRequest, /user/)
    end

    it 'rejects negative write_off' do
      expect { described_class.submit!(valid.merge(write_off: -5)) }
        .to raise_error(described_class::InvalidRequest, /write_off/)
    end
  end
end
