module Teyca
  module Services
    class SubmitService
      class Error < StandardError; end
      class OperationNotFound      < Error; end
      class OperationForbidden     < Error; end
      class OperationAlreadyDone   < Error; end
      class InvalidWriteOff        < Error; end
      class WriteOffExceedsAllowed < Error; end
      class WriteOffExceedsBonus   < Error; end

      def initialize(user:, operation_id:, write_off:, db: Teyca::Database.connection)
        @user_payload = user || {}
        @operation_id = operation_id
        @write_off    = Money.to_d(write_off)
        @db           = db
      end

      def call
        validate_owner!

        @db.transaction(**transaction_opts) do
          lock_rows!
          validate_state!
          apply_changes!
        end

        Presenter.new(user: user, operation: operation).to_h
      end

      private

      def operation
        @operation ||= Teyca::Models::Operation[@operation_id] ||
                       raise(OperationNotFound, "Операция #{@operation_id} не найдена")
      end

      def user
        @user ||= Teyca::Models::User[@user_payload[:id]] ||
                  raise(OperationNotFound, "Пользователь #{@user_payload[:id]} не найден")
      end

      def validate_owner!
        raise OperationForbidden, 'Операция принадлежит другому пользователю' if operation.user_id != user.id
      end

      # SQLite silently ignores SELECT...FOR UPDATE, so row locks alone do not
      # serialize concurrent submits. An IMMEDIATE transaction takes the database
      # write lock at BEGIN, making a second submit of the same operation wait for
      # the first to commit (and then observe done? == true). On adapters that do
      # support row locks the option is ignored and for_update does the serializing.
      def transaction_opts
        @db.database_type == :sqlite ? { mode: :immediate } : {}
      end

      # Re-read and lock both rows inside the transaction. The @operation/@user
      # cached by validate_owner! were read before BEGIN; validating against them
      # lets a parallel submit pass validate_state! on a stale done? == false and
      # write off the bonus twice. Re-fetching under FOR UPDATE closes that race.
      def lock_rows!
        @user = Teyca::Models::User.where(id: user.id).for_update.first ||
                raise(OperationNotFound, "Пользователь #{@user_payload[:id]} не найден")
        @operation = Teyca::Models::Operation.where(id: operation.id).for_update.first ||
                     raise(OperationNotFound, "Операция #{@operation_id} не найдена")
      end

      def validate_state!
        raise InvalidWriteOff,        'Сумма списания не может быть отрицательной' if @write_off.negative?
        raise OperationAlreadyDone,   "Операция #{operation.id} уже подтверждена" if operation.done?
        raise WriteOffExceedsAllowed, "Максимально допустимое списание: #{allowed_write_off}" if @write_off > allowed_write_off
        raise WriteOffExceedsBonus,   "Недостаточно бонусов: доступно #{user.bonus}" if @write_off > Money.to_d(user.bonus)
      end

      def apply_changes!
        operation.update(write_off: @write_off, cashback: new_cashback, done: true)
        Teyca::Models::User
          .where(id: user.id)
          .update(bonus: Money.to_d(user.bonus) - @write_off + new_cashback)
        user.refresh
      end

      def allowed_write_off
        @allowed_write_off ||= Money.to_d(operation.allowed_write_off)
      end

      def new_cashback
        @new_cashback ||= begin
          if allowed_write_off.zero?
            Money.to_d(0)
          else
            factor = (allowed_write_off - @write_off) / allowed_write_off
            Money.round(Money.to_d(operation.cashback) * factor)
          end
        end
      end

      class Presenter
        def initialize(user:, operation:)
          @user      = user
          @operation = operation
        end

        def to_h
          {
            status: 'ok',
            message: 'Операция подтверждена',
            operation: {
              user_id:          @user.id,
              cashback:         m(@operation.cashback),
              cashback_percent: m(@operation.cashback_percent),
              discount:         m(@operation.discount),
              discount_percent: m(@operation.discount_percent),
              write_off:        m(@operation.write_off),
              to_pay:           m(Money.to_d(@operation.check_summ) - Money.to_d(@operation.write_off))
            }
          }
        end

        private

        def m(value) = Money.to_json_number(value)
      end
    end
  end
end
