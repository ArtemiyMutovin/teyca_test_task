module Teyca
  module Services
    module Modifiers
      class DiscountModifier < Base
        def discount_percent(template_percent)
          template_percent + product.value.to_f
        end

        def description
          "Дополнительная скидка #{product.value}%"
        end
      end
    end
  end
end
