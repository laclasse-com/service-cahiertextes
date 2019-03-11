# frozen_string_literal: true

class Content < Sequel::Model( :contents )
    many_to_many :attachments, join_table: :contents_attachments
    many_to_many :targets, join_table: :contents_users, class: :User, left_key: :content_id, right_key: :user_id
    many_to_one :assignment_type
    many_to_one :author, key: :author_id, class: :User
    many_to_one :timeslot
    many_to_one :parent, key: :parent_content_id, class: :Content
    many_to_one :trail
    one_to_many :assignment_done_markers

    def to_deep_hash
        hash = to_hash

        hash[:attachments] = attachments.map(&:to_hash)
        # hash[:assignments] = timeslot_contents.select { |assignment| assignment.dtime.nil? || assignment.dtime > UNDELETE_TIME_WINDOW.minutes.ago }
        # hash[:assignments].each do |assignment|
        #     assignment[:attachments] = assignment.attachments.map(&:to_hash)
        # end
        # hash[:assignments] = hash[:assignments].map(&:to_hash)

        hash
    end

    def modify( params )
        self.mtime = Time.now
        self.timeslot_id = params['timeslot_id'] if params.key?( 'timeslot_id' )
        self.stime = params['stime'] if params.key?( 'stime' )
        self.content = params['content'] if params.key?( 'content' )
        self.date = params['date'] if params.key?( 'date' )

        self.assignment_type = params['assignment_type'] if params.key?( 'assignment_type' )
        self.load = params['load'] if params.key?( 'load' )
        self.parent_content_id = params['session_id'] if params.key?( 'session_id' )

        if params['attachments']
            remove_all_attachments
            params['attachments'].each do |attachment|
                add_attachment( DataManagement::Accessors.create_or_get( Attachment,
                                                                         name: attachment['name'],
                                                                         hash: attachment['hash'] ) )
            end
        end

        save
    end

    def done_by!( author_id )
        add_assignment_done_marker( author_id: author_id, rtime: Time.now ) if type == 'assignment'
    end

    def done_by?( author_id )
        assignment_done_markers_dataset.where( author_id: author_id ).count.positive? if type == 'assignment'
    end

    def done_on_the( author_id )
        assignment_done_markers_dataset.where( author_id: author_id ).first[:rtime] if type == 'assignment'
    end

    def to_be_done_by!( author_id )
        assignment_done_markers_dataset.where( author_id: author_id ).destroy if type == 'assignment'
    end
end

class ContentAttachment < Sequel::Model( :contents_attachments )
end

class AssignmentDoneMarker < Sequel::Model( :assignment_done_markers )
    many_to_one :contents
    many_to_one :author, key: :author_id, class: :User
end
