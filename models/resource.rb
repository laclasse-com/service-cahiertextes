# frozen_string_literal: true

class Resource < Sequel::Model( :resources )
    many_to_many :sessions, join_table: :sessions_resources
    many_to_many :assignments, join_table: :assignments_resources
end
