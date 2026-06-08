module Teyca
  module Services
    module RequestValidator
      class InvalidRequest < StandardError; end

      module_function

      def operation!(payload)
        require_integer!(payload, :user_id)
        positions = payload[:positions]
        raise InvalidRequest, 'positions должен быть непустым массивом' unless positions.is_a?(Array) && !positions.empty?

        positions.each_with_index do |pos, idx|
          raise InvalidRequest, "positions[#{idx}] должен быть объектом" unless pos.is_a?(Hash)
          require_integer!(pos, :id,       prefix: "positions[#{idx}].")
          require_positive_number!(pos, :price,    prefix: "positions[#{idx}].")
          require_positive_number!(pos, :quantity, prefix: "positions[#{idx}].")
        end
      end

      def submit!(payload)
        user = payload[:user]
        raise InvalidRequest, 'user обязателен' unless user.is_a?(Hash)
        require_integer!(user, :id, prefix: 'user.')
        require_integer!(payload, :operation_id)
        require_non_negative_number!(payload, :write_off)
      end

      def require_integer!(hash, key, prefix: '')
        value = hash[key]
        raise InvalidRequest, "#{prefix}#{key} должен быть целым числом" unless value.is_a?(Integer)
      end

      def require_positive_number!(hash, key, prefix: '')
        value = hash[key]
        raise InvalidRequest, "#{prefix}#{key} должен быть положительным числом" unless value.is_a?(Numeric) && value.positive?
      end

      def require_non_negative_number!(hash, key, prefix: '')
        value = hash[key]
        raise InvalidRequest, "#{prefix}#{key} должен быть неотрицательным числом" unless value.is_a?(Numeric) && value >= 0
      end
    end
  end
end
