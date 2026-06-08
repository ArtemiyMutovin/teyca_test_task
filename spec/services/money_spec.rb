require 'spec_helper'

RSpec.describe Teyca::Services::Money do
  describe '.to_d' do
    it 'returns BigDecimal for numeric input' do
      expect(described_class.to_d(10.5)).to eq(BigDecimal('10.5'))
    end

    it 'returns BigDecimal for string input' do
      expect(described_class.to_d('15.25')).to eq(BigDecimal('15.25'))
    end

    it 'returns zero for nil' do
      expect(described_class.to_d(nil)).to eq(BigDecimal('0'))
    end
  end

  describe '.round' do
    it 'rounds to two decimals' do
      expect(described_class.round(1.236)).to eq(BigDecimal('1.24'))
    end
  end

  describe '.to_json_number' do
    it 'returns a Float ready for JSON output' do
      expect(described_class.to_json_number(BigDecimal('734'))).to eq(734.0)
      expect(described_class.to_json_number('31.7')).to eq(31.7)
    end

    it 'rounds half-up to two decimals' do
      expect(described_class.to_json_number(BigDecimal('1.235'))).to eq(1.24)
    end
  end
end
