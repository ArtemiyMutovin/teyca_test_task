module Teyca
  module Routes
    module Submissions
      ERROR_STATUS = {
        Teyca::Services::SubmitService::OperationNotFound      => 404,
        Teyca::Services::SubmitService::OperationForbidden     => 403,
        Teyca::Services::SubmitService::OperationAlreadyDone   => 409,
        Teyca::Services::SubmitService::InvalidWriteOff        => 422,
        Teyca::Services::SubmitService::WriteOffExceedsAllowed => 422,
        Teyca::Services::SubmitService::WriteOffExceedsBonus   => 422
      }.freeze

      def self.registered(app)
        app.post '/submit' do
          Teyca::Services::RequestValidator.submit!(@payload)

          result = Teyca::Services::SubmitService.new(
            user:         @payload[:user],
            operation_id: @payload[:operation_id],
            write_off:    @payload[:write_off]
          ).call

          status 200
          result.to_json
        rescue Teyca::Services::RequestValidator::InvalidRequest => e
          status 422
          { status: 'error', message: e.message }.to_json
        rescue Teyca::Services::SubmitService::Error => e
          status ERROR_STATUS.fetch(e.class, 422)
          { status: 'error', message: e.message }.to_json
        end
      end
    end
  end
end
