module Teyca
  module Services
    module Modifiers
      class NullModifier < Base
        def type;        nil; end
        def value;       nil; end
        def description; 'Стандартные правила программы лояльности'; end
      end
    end
  end
end
