# frozen_string_literal: true

class Trail < Sequel::Model( :trails )
    many_to_many :contents, join_table: :contents_trails
end

class ContentTrail < Sequel::Model( :contents_trails )
end
