module Teyca
  module Services
    class OperationCalculator
      class UserNotFound < StandardError; end

      def initialize(user_id:, positions:, db: Teyca::Database.connection)
        @user_id   = user_id
        @positions = positions
        @db        = db
      end

      def call
        results   = position_results
        aggregate = Aggregate.new(results)
        operation = @db.transaction { persist!(aggregate) }
        Presenter.new(user: user, operation: operation, aggregate: aggregate, results: results).to_h
      end

      private

      def user
        @user ||= Teyca::Models::User[@user_id] || raise(UserNotFound, "Пользователь #{@user_id} не найден")
      end

      def template
        @template ||= Teyca::Models::Template[user.template_id]
      end

      def products
        @products ||= Teyca::Models::Product
                      .where(id: @positions.map { _1[:id] })
                      .all
                      .to_h { |p| [p.id, p] }
      end

      def position_results
        @positions.map do |input|
          modifier = Modifiers.for(products[input[:id]])
          PositionCalculator.new(input: input, template: template, modifier: modifier).call
        end
      end

      def persist!(aggregate)
        Teyca::Models::Operation.create(
          user_id:           user.id,
          cashback:          aggregate.total_cashback,
          cashback_percent:  aggregate.cashback_percent,
          discount:          aggregate.total_discount,
          discount_percent:  aggregate.discount_percent,
          check_summ:        aggregate.total_payable,
          allowed_write_off: aggregate.allowed_write_off,
          write_off:         0,
          done:              false
        )
      end

      class Aggregate
        attr_reader :results

        def initialize(results)
          @results = results
        end

        def total_subtotal    = sum_by(&:subtotal)
        def total_discount    = sum_by(&:discount_value)
        def total_payable     = sum_by(&:payable)
        def total_cashback    = sum_by(&:cashback_value)
        def allowed_write_off = sum_by { |r| r.loyalty_eligible? ? r.payable : 0 }

        def discount_percent
          total_subtotal.zero? ? Money.to_d(0) : Money.round(total_discount * 100 / total_subtotal)
        end

        def cashback_percent
          total_payable.zero? ? Money.to_d(0) : Money.round(total_cashback * 100 / total_payable)
        end

        private

        def sum_by(&blk)
          @results.sum(Money.to_d(0)) { |r| Money.to_d(blk.call(r)) }
        end
      end

      class Presenter
        def initialize(user:, operation:, aggregate:, results:)
          @user      = user
          @operation = operation
          @aggregate = aggregate
          @results   = results
        end

        def to_h
          {
            status: 'ok',
            user: user_payload,
            operation_id: @operation.id,
            summ: m(@aggregate.total_payable),
            bonus_info: {
              balance:                m(@user.bonus),
              allowed_write_off:      m(@aggregate.allowed_write_off),
              total_cashback_percent: m(@aggregate.cashback_percent),
              will_be_credited:       m(@aggregate.total_cashback)
            },
            discount_info: {
              total_discount:         m(@aggregate.total_discount),
              total_discount_percent: m(@aggregate.discount_percent)
            },
            positions: @results.map(&:to_h)
          }
        end

        private

        def user_payload
          { id: @user.id, name: @user.name, template_id: @user.template_id, bonus: m(@user.bonus) }
        end

        def m(value) = Money.to_json_number(value)
      end
    end
  end
end
