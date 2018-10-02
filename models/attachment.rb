# frozen_string_literal: true

class Attachment < Sequel::Model( :attachments )
    many_to_many :sessions, join_table: :sessions_attachments
    many_to_many :assignments, join_table: :assignments_attachments
    many_to_one :attachment_types
end

class AttachmentType < Sequel::Model( :attachment_types )
end
