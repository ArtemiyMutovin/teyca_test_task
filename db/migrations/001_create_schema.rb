# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:templates) do
      primary_key :id
      String  :name, null: false
      Integer :discount, null: false, default: 0
      Integer :cashback, null: false, default: 0
    end

    create_table(:users) do
      primary_key :id
      foreign_key :template_id, :templates
      String  :name, null: false
      Numeric :bonus, null: false, default: 0
    end

    create_table(:products) do
      primary_key :id
      String :name, null: false
      String :type
      String :value
    end

    create_table(:operations) do
      primary_key :id
      foreign_key :user_id, :users
      Numeric :cashback,          null: false, default: 0
      Numeric :cashback_percent,  null: false, default: 0
      Numeric :discount,          null: false, default: 0
      Numeric :discount_percent,  null: false, default: 0
      Numeric :write_off,         null: false, default: 0
      Numeric :check_summ,        null: false, default: 0
      Numeric :allowed_write_off, null: false, default: 0
      TrueClass :done,            null: false, default: false
    end
  end
end
