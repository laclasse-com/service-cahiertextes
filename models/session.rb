class Session < Sequel::Model( :sessions )
  many_to_many :resources
  many_to_one :timeslot
  many_to_one :textbook
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

  def toggle_deleted
    update( deleted: !deleted, mtime: Time.now )
    save

    assignments.each do |assignment|
      if deleted
        assignment.update( deleted: deleted, mtime: Time.now )
      elsif assignment.mtime <= UNDELETE_TIME_WINDOW.minutes.ago
        assignment.update( deleted: deleted, mtime: Time.now )
      end
      assignment.save
    end
  end

  def toggle_validated
    self.vtime = vtime.nil? ? Time.now : nil

    save
  end

  def modifie( params )
    self.contenu = params['contenu']
    self.mtime = Time.now

    if params['resources']
      remove_all_resources
      params['resources'].each do |resource|
        add_resource( DataManagement::Accessors.create_or_get( Resource, name: resource['name'],
                                                                           hash: resource['hash'] ) )
      end
    end

    save
  end

  def copie( group_id, timeslot_id, date_session )
    textbook = TextBook.where( group_id: group_id ).first
    textbook = TextBook.create( ctime: Time.now, group_id: group_id ) if textbook.nil?

    target_session = Session.where( textbook_id: textbook.id,
                                timeslot_id: timeslot_id,
                                date_session: date_session ).first
    if target_session.nil?
      target_session = Session.create( textbook_id: textbook.id,
                                   timeslot_id: timeslot_id,
                                   date_session: date_session,
                                   ctime: Time.now,
                                   contenu: contenu,
                                   enseignant_id: enseignant_id )
    end
    resources.each do |resource|
      target_session.add_resource( resource )
    end

    target_session
  end
end

class SessionResource < Sequel::Model( :sessions_resources )
end
