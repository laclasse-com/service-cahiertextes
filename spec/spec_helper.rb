require 'rubygems'

ENV["RACK_ENV"] ||= 'test'

require 'rack/test'
require 'sequel'
require 'tsort'

require_relative '../config/environment'
require_relative '../config/database'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
end

require_relative '../app'

class TableCleaner
  def initialize db, excluded_tables
    @db = db
    @excluded_tables = excluded_tables
  end

  def clean
    @db.transaction do
      tables_to_clean do |t|
        @db[t].delete
      end
    end
  end

  private
  include TSort

  def tables_to_clean &block
    tsort.reverse.each &block
  end

  def tsort_each_node &block
    @db.tables.each do |t|
      block.call t unless @excluded_tables.include? t
    end
  end

  def tsort_each_child table, &block
    @db.foreign_key_list(table).each do |fk|
      block.call fk[:table] unless @excluded_tables.include? fk[:table]
    end
  end
end

# # Example usage.
# cleaner = TableCleaner.new DB, [:spatial_ref_sys]
# cleaner.clean
