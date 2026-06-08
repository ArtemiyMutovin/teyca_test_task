require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :db do
  desc 'Run pending Sequel migrations'
  task :migrate do
    require 'sequel'
    Sequel.extension :migration
    require_relative 'config/database'
    db = Teyca::Database.connection
    Sequel::Migrator.run(db, File.expand_path('db/migrations', __dir__))
    puts "Migrated #{db.opts[:database]}"
  end

  desc 'Load seed data'
  task :seed do
    require_relative 'config/database'
    require_relative 'db/seeds'
    Teyca::Seeds.run
    puts 'Seeded database'
  end

  desc 'Migrate and seed a fresh database'
  task setup: %i[migrate seed]
end
