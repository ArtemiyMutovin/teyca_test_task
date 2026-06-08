ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'json'

require_relative '../app'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.around do |example|
    Teyca::Database.connection.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end

module RackHelpers
  include Rack::Test::Methods
  def app
    Teyca::App
  end
end

RSpec.configure { |c| c.include RackHelpers, type: :request }
