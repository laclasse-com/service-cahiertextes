# frozen_string_literal: true

class Attachment < Sequel::Model( :attachments )
    many_to_many :sessions, join_table: :sessions_attachments
    many_to_many :assignments, join_table: :assignments_attachments
    many_to_many :notes, join_table: :notes_attachments
end
