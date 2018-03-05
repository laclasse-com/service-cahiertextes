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

  def tsort_each_node
    @db.tables.each do |t|
      yield t unless @excluded_tables.include? t
    end
  end

  def tsort_each_child( table )
    @db.foreign_key_list(table).each do |fk|
      yield fk[:table] unless @excluded_tables.include? fk[:table]
    end
  end
end
