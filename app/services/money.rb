require 'bigdecimal'
require 'bigdecimal/util'

module Teyca
  module Services
    module Money
      SCALE = 2

      module_function

      def to_d(value)
        case value
        when BigDecimal then value
        when Numeric    then value.to_d
        when String     then value.to_d
        when nil        then BigDecimal('0')
        else value.to_s.to_d
        end
      end

      def round(value)
        to_d(value).round(SCALE)
      end

      def to_json_number(value)
        round(value).to_s('F').to_f
      end
    end
  end
end
