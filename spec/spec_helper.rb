ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'json'

# Build the schema before loading the app: the Sequel models query their table
# layout at load time, so the tables must already exist. This lets a clean
# checkout run `bundle exec rspec` without a separate `rake db:setup` step.
require 'sequel'
Sequel.extension :migration
require_relative '../config/database'
Sequel::Migrator.run(Teyca::Database.connect, File.expand_path('../db/migrations', __dir__))

require_relative '../app'
require_relative '../db/seeds'

RSpec.configure do |config|
  # Load canonical seed data once. The seed is idempotent and per-example
  # mutations are rolled back by the around hook below.
  config.before(:suite) { Teyca::Seeds.run }

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
