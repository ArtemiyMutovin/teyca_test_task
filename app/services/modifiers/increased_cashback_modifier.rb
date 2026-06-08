module Teyca
  module Services
    module Modifiers
      class IncreasedCashbackModifier < Base
        def cashback_percent(template_percent)
          template_percent + product.value.to_f
        end

        def description
          "Повышенный кэшбек +#{product.value}%"
        end
      end
    end
  end
end
