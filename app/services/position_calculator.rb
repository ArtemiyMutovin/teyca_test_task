module Teyca
  module Services
    class PositionCalculator
      Result = Struct.new(
        :id, :price, :quantity, :subtotal,
        :discount_percent, :discount_value, :payable,
        :cashback_percent, :cashback_value,
        :type, :value, :description, :loyalty_eligible,
        keyword_init: true
      ) do
        def loyalty_eligible?; loyalty_eligible; end

        def to_h
          {
            id: id, price: price, quantity: quantity,
            type: type, value: value, description: description,
            discount_percent: Money.to_json_number(discount_percent),
            discount_value:   Money.to_json_number(discount_value)
          }
        end
      end

      def initialize(input:, template:, modifier:)
        @input    = input
        @template = template
        @modifier = modifier
      end

      def call
        Result.new(
          id: id, price: price, quantity: quantity, subtotal: subtotal,
          discount_percent: discount_percent, discount_value: discount_value, payable: payable,
          cashback_percent: cashback_percent, cashback_value: cashback_value,
          type: @modifier.type, value: @modifier.value, description: @modifier.description,
          loyalty_eligible: @modifier.loyalty_eligible?
        )
      end

      private

      def id;       @input[:id]; end
      def price;    @input[:price]; end
      def quantity; @input[:quantity]; end

      def subtotal
        @subtotal ||= Money.to_d(price) * Money.to_d(quantity)
      end

      def discount_percent
        @discount_percent ||= Money.to_d(@modifier.discount_percent(@template.discount))
      end

      def cashback_percent
        @cashback_percent ||= Money.to_d(@modifier.cashback_percent(@template.cashback))
      end

      def discount_value
        @discount_value ||= Money.round(subtotal * discount_percent / 100)
      end

      def payable
        @payable ||= Money.round(subtotal - discount_value)
      end

      def cashback_value
        @cashback_value ||= Money.round(payable * cashback_percent / 100)
      end
    end
  end
end
