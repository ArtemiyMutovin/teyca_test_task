module Teyca
  module Routes
    module Operations
      def self.registered(app)
        app.post '/operation' do
          Teyca::Services::RequestValidator.operation!(@payload)

          result = Teyca::Services::OperationCalculator.new(
            user_id:   @payload[:user_id],
            positions: @payload[:positions]
          ).call

          status 200
          result.to_json
        rescue Teyca::Services::RequestValidator::InvalidRequest => e
          status 422
          { status: 'error', message: e.message }.to_json
        rescue Teyca::Services::OperationCalculator::UserNotFound => e
          status 404
          { status: 'error', message: e.message }.to_json
        end
      end
    end
  end
end
