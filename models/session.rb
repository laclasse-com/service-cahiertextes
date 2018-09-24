# frozen_string_literal: true

class Session < Sequel::Model( :sessions )
    many_to_many :resources, join_table: :sessions_resources
    many_to_one :timeslot
    one_to_many :assignments

    def to_deep_hash
        hash = to_hash

        hash[:resources] = resources.map(&:to_hash)
        hash[:assignments] = assignments.select { |assignment| !assignment.deleted || assignment.mtime > UNDELETE_TIME_WINDOW.minutes.ago }
        hash[:assignments].each do |assignment|
            assignment[:resources] = assignment.resources.map(&:to_hash)
        end
        hash[:assignments] = hash[:assignments].map(&:to_hash)

        hash
    end

    def modify( params )
        self.mtime = Time.now

        self.content = params['content'] if params.key?( 'content' )
        self.date = params['date'] if params.key?( 'date' )

        if params['resources']
            remove_all_resources
            params['resources'].each do |resource|
                add_resource( DataManagement::Accessors.create_or_get( Resource, name: resource['name'],
                                                                                 hash: resource['hash'] ) )
            end
        end

        save
    end
end

class SessionResource < Sequel::Model( :sessions_resources )
end
