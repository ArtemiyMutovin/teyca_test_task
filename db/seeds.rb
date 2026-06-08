# frozen_string_literal: true

# Idempotent seed data for development and the test suite. Run via `rake db:seed`
# (or `rake db:setup` to migrate + seed a fresh database). Existing rows with the
# same primary key are replaced so re-running the seed is safe.
module Teyca
  module Seeds
    TEMPLATES = [
      { id: 1, name: 'Bronze', discount: 0,  cashback: 5 },
      { id: 2, name: 'Silver', discount: 5,  cashback: 5 },
      { id: 3, name: 'Gold',   discount: 15, cashback: 0 }
    ].freeze

    USERS = [
      { id: 1, template_id: 1, name: 'Иван',   bonus: 10_000 },
      { id: 2, template_id: 2, name: 'Марина', bonus: 10_000 },
      { id: 3, template_id: 3, name: 'Женя',   bonus: 10_000 }
    ].freeze

    # Positions referencing ids without a product row fall back to the plain
    # template behaviour (see Modifiers.for), so not every position id is seeded.
    PRODUCTS = [
      { id: 2, name: 'Молоко', type: 'increased_cashback', value: '10' },
      { id: 3, name: 'Хлеб',   type: 'discount',           value: '15' },
      { id: 4, name: 'Сахар',  type: 'noloyalty',          value: nil }
    ].freeze

    def self.run(db = Teyca::Database.connection)
      db.transaction do
        db[:templates].insert_conflict(:replace).multi_insert(TEMPLATES)
        db[:users].insert_conflict(:replace).multi_insert(USERS)
        db[:products].insert_conflict(:replace).multi_insert(PRODUCTS)
      end
    end
  end
end
