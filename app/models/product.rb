require 'sequel'

module Teyca
  module Models
    class Product < Sequel::Model(:products)
      DISCOUNT = 'discount'.freeze
      INCREASED_CASHBACK = 'increased_cashback'.freeze
      NOLOYALTY = 'noloyalty'.freeze
    end
  end
end
