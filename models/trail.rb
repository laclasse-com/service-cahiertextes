# frozen_string_literal: true

class Trail < Sequel::Model( :trails )
    one_to_many :contents
end
