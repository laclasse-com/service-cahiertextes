class Cours < Sequel::Model( :cours )
  many_to_many :resources
  many_to_one :timeslot
  many_to_one :textbook
  one_to_many :devoirs

  def to_deep_hash
    hash = to_hash

    hash[:resources] = resources.map(&:to_hash)
    hash[:devoirs] = devoirs.select { |devoir| !devoir.deleted || devoir.date_modification > UNDELETE_TIME_WINDOW.minutes.ago }
    hash[:devoirs].each do |devoir|
      devoir[:resources] = devoir.resources.map(&:to_hash)
    end
    hash[:devoirs] = hash[:devoirs].map(&:to_hash)

    hash
  end

  def toggle_deleted
    update( deleted: !deleted, date_modification: Time.now )
    save

    devoirs.each do |devoir|
      if deleted
        devoir.update( deleted: deleted, date_modification: Time.now )
      elsif devoir.date_modification <= UNDELETE_TIME_WINDOW.minutes.ago
        devoir.update( deleted: deleted, date_modification: Time.now )
      end
      devoir.save
    end
  end

  def toggle_validated
    self.date_validation = date_validation.nil? ? Time.now : nil

    save
  end

  def modifie( params )
    self.contenu = params['contenu']
    self.date_modification = Time.now

    if params['resources']
      remove_all_resources
      params['resources'].each do |resource|
        add_resource( DataManagement::Accessors.create_or_get( Resource, name: resource['name'],
                                                                           hash: resource['hash'] ) )
      end
    end

    save
  end

  def copie( group_id, timeslot_id, date_cours )
    textbook = TextBook.where( group_id: group_id ).first
    textbook = TextBook.create( date_creation: Time.now, group_id: group_id ) if textbook.nil?

    target_cours = Cours.where( textbook_id: textbook.id,
                                timeslot_id: timeslot_id,
                                date_cours: date_cours ).first
    if target_cours.nil?
      target_cours = Cours.create( textbook_id: textbook.id,
                                   timeslot_id: timeslot_id,
                                   date_cours: date_cours,
                                   date_creation: Time.now,
                                   contenu: contenu,
                                   enseignant_id: enseignant_id )
    end
    resources.each do |resource|
      target_cours.add_resource( resource )
    end

    target_cours
  end
end

class CoursResource < Sequel::Model( :cours_resources )
end
