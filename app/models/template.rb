require 'sequel'

module Teyca
  module Models
    class Template < Sequel::Model(:templates)
      one_to_many :users, key: :template_id, class: 'Teyca::Models::User'
    end
  end
end
