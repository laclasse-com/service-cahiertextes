# frozen_string_literal: true

class AssignmentDoneMarker < Sequel::Model( :assignment_done_markers )
    many_to_one :content
    many_to_one :author, key: :author_id, class: :User
end
