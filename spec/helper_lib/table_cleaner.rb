# encoding: utf-8

# Example usage:
# cleaner = TableCleaner.new DB, [:spatial_ref_sys]
# cleaner.clean
class TableCleaner
  def initialize( db, excluded_tables )
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

  def tables_to_clean( &block )
    tsort.reverse_each( &block )
  end

  def tsort_each_node( &block )
    @db.tables.each do |t|
      block.call t unless @excluded_tables.include? t
    end
  end

  def tsort_each_child( table, &block )
    @db.foreign_key_list(table).each do |fk|
      block.call fk[:table] unless @excluded_tables.include? fk[:table]
    end
  end
end
