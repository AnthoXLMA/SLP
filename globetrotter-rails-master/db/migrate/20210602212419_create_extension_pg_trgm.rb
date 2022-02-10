# frozen_string_literal: true

class CreateExtensionPgTrgm < ActiveRecord::Migration[6.1]
  def change
    execute('create extension pg_trgm')
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.message.start_with?('PG::DuplicateObject') # ERROR:  extension "pg_trgm" already exists'

    puts 'extension pg_trgm already exists'
    ActiveRecord::Base.connection.execute 'ROLLBACK'
  end
end
