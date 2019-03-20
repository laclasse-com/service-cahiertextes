# frozen_string_literal: true

class User < Sequel::Model( :users )
    one_to_many :authored_timeslots, key: :author_id, class: :Timeslot
    one_to_many :authored_contents, key: :author_id, class: :Content
    one_to_many :authored_resources, key: :author_id, class: :Resource
    one_to_many :authored_reservations, key: :author_id, class: :Reservation
    one_to_many :authored_assignment_done_markers, key: :author_id, class: :AssignmentDoneMarker
    one_to_many :authored_imports, key: :author_id, class: :Import

    many_to_many :timeslots, join_table: :timeslots_users
    many_to_many :contents, join_table: :contents_users
end
