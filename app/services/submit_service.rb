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

        @db.transaction do
          locked_user!
          validate_state!
          apply_changes!
        end

        Presenter.new(user: user, operation: operation).to_h
      end

      private

      def operation
        @operation ||= Teyca::Models::Operation[@operation_id] ||
                       raise(OperationNotFound, "Operation #{@operation_id} not found")
      end

      def user
        @user ||= Teyca::Models::User[@user_payload[:id]] ||
                  raise(OperationNotFound, "User #{@user_payload[:id]} not found")
      end

      def validate_owner!
        raise OperationForbidden, 'Operation belongs to another user' if operation.user_id != user.id
      end

      def locked_user!
        # Re-fetch under SELECT...FOR UPDATE so concurrent submits serialize.
        row = Teyca::Models::User.where(id: user.id).for_update.first
        @user = row || raise(OperationNotFound, "User #{@user_payload[:id]} not found")
      end

      def validate_state!
        raise InvalidWriteOff,        'write_off must be non-negative' if @write_off.negative?
        raise OperationAlreadyDone,   "Operation #{operation.id} already done" if operation.done?
        raise WriteOffExceedsAllowed, "max allowed is #{allowed_write_off}" if @write_off > allowed_write_off
        raise WriteOffExceedsBonus,   "user bonus is #{user.bonus}" if @write_off > Money.to_d(user.bonus)
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
