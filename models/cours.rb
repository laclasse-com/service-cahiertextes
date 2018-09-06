class Cours < Sequel::Model( :cours )
  many_to_many :ressources
  many_to_one :creneau_emploi_du_temps
  many_to_one :textbook
  one_to_many :devoirs

  def to_deep_hash
    hash = to_hash

    hash[:ressources] = ressources.map(&:to_hash)
    hash[:devoirs] = devoirs.select { |devoir| !devoir.deleted || devoir.date_modification > UNDELETE_TIME_WINDOW.minutes.ago }
    hash[:devoirs].each do |devoir|
      devoir[:ressources] = devoir.ressources.map(&:to_hash)
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

    if params['ressources']
      remove_all_ressources
      params['ressources'].each do |ressource|
        add_ressource( DataManagement::Accessors.create_or_get( Ressource, name: ressource['name'],
                                                                           hash: ressource['hash'] ) )
      end
    end

    save
  end

  def copie( regroupement_id, creneau_emploi_du_temps_id, date_cours )
    textbook = TextBook.where( regroupement_id: regroupement_id ).first
    textbook = TextBook.create( date_creation: Time.now, regroupement_id: regroupement_id ) if textbook.nil?

    target_cours = Cours.where( textbook_id: textbook.id,
                                creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
                                date_cours: date_cours ).first
    if target_cours.nil?
      target_cours = Cours.create( textbook_id: textbook.id,
                                   creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
                                   date_cours: date_cours,
                                   date_creation: Time.now,
                                   contenu: contenu,
                                   enseignant_id: enseignant_id )
    end
    ressources.each do |ressource|
      target_cours.add_ressource( ressource )
    end

    target_cours
  end
end

class CoursRessource < Sequel::Model( :cours_ressources )
end
