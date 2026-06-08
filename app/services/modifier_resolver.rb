module Teyca
  module Services
    module Modifiers
      REGISTRY = {
        Teyca::Models::Product::DISCOUNT           => DiscountModifier,
        Teyca::Models::Product::INCREASED_CASHBACK => IncreasedCashbackModifier,
        Teyca::Models::Product::NOLOYALTY          => NoLoyaltyModifier
      }.freeze

      NULL = NullModifier.new.freeze

      def self.for(product)
        klass = product && REGISTRY[product.type]
        klass ? klass.new(product) : NULL
      end
    end
  end
end
