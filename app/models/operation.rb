require 'sequel'

module Teyca
  module Models
    class Operation < Sequel::Model(:operations)
      many_to_one :user, key: :user_id, class: 'Teyca::Models::User'

      def done?
        value = self[:done]
        value == true || value == 1
      end
    end
  end
end
