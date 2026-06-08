module Teyca
  module Services
    module Modifiers
      class Base
        attr_reader :product

        def initialize(product = nil)
          @product = product
        end

        def discount_percent(template_percent)
          template_percent
        end

        def cashback_percent(template_percent)
          template_percent
        end

        def loyalty_eligible?
          true
        end

        def type
          product&.type
        end

        def value
          product&.value
        end

        def description
          ''
        end
      end
    end
  end
end
