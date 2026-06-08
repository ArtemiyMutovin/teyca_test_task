module Teyca
  module Services
    module Modifiers
      class NoLoyaltyModifier < Base
        def discount_percent(_template_percent); 0; end
        def cashback_percent(_template_percent); 0; end
        def loyalty_eligible?; false; end

        def description
          'Товар не участвует в программе лояльности'
        end
      end
    end
  end
end
