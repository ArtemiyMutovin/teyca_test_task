require 'sequel'
require 'logger'

module Teyca
  class Database
    DEFAULT_PATH = File.expand_path('../test.db', __dir__)

    def self.connect(path: ENV.fetch('TEYCA_DB_PATH', DEFAULT_PATH), logger: nil)
      @connection ||= Sequel.sqlite(path).tap do |db|
        db.loggers << logger if logger
        Sequel::Model.db = db
      end
    end

    def self.connection
      @connection || connect
    end

    def self.reset!
      @connection&.disconnect
      @connection = nil
    end
  end
end
