require 'sinatra/base'
require 'sinatra/json'
require 'json'

require_relative 'config/database'
Teyca::Database.connect

require_relative 'app/models/template'
require_relative 'app/models/user'
require_relative 'app/models/product'
require_relative 'app/models/operation'

require_relative 'app/services/money'
require_relative 'app/services/modifiers/base'
require_relative 'app/services/modifiers/null_modifier'
require_relative 'app/services/modifiers/discount_modifier'
require_relative 'app/services/modifiers/increased_cashback_modifier'
require_relative 'app/services/modifiers/no_loyalty_modifier'
require_relative 'app/services/modifier_resolver'
require_relative 'app/services/position_calculator'
require_relative 'app/services/operation_calculator'
require_relative 'app/services/submit_service'
require_relative 'app/services/request_validator'

require_relative 'app/routes/operations'
require_relative 'app/routes/submissions'

module Teyca
  class App < Sinatra::Base
    helpers Sinatra::JSON

    configure do
      set :show_exceptions, false
      set :raise_errors, false
    end

    before do
      content_type :json
      raw = request.body.read
      @payload = raw.empty? ? {} : JSON.parse(raw, symbolize_names: true)
    rescue JSON::ParserError
      halt 400, { status: 'error', message: 'Invalid JSON' }.to_json
    end

    error StandardError do
      err = env['sinatra.error']
      status 500
      json status: 'error', message: err.message
    end

    register Teyca::Routes::Operations
    register Teyca::Routes::Submissions
  end
end
