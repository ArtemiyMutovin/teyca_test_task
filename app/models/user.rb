require 'sequel'

module Teyca
  module Models
    class User < Sequel::Model(:users)
      many_to_one :template, key: :template_id, class: 'Teyca::Models::Template'
      one_to_many :operations, key: :user_id, class: 'Teyca::Models::Operation'
    end
  end
end
