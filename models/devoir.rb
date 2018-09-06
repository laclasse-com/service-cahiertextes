class Devoir < Sequel::Model( :devoirs )
  many_to_many :resources
  many_to_one :timeslot
  many_to_one :type_devoir
  one_to_many :devoir_todo_items
  many_to_one :cours

  def to_deep_hash
    hash = to_hash

    hash[:resources] = resources.map(&:to_hash)

    hash
  end

  def fait_par!( eleve_id )
    add_devoir_todo_item( eleve_id: eleve_id, date_fait: Time.now )
  end

  def fait_par?( eleve_id )
    devoir_todo_items_dataset.where(eleve_id: eleve_id).count > 0
  end

  def fait_le( eleve_id )
    devoir_todo_items_dataset.where(eleve_id: eleve_id).first[:date_fait]
  end

  def a_faire_par!( eleve_id )
    devoir_todo_items_dataset.where(eleve_id: eleve_id).destroy
  end

  def toggle_deleted
    update( deleted: !deleted, date_modification: Time.now )
    save
  end

  def toggle_fait( user )
    fait_par?( user['id'] ) ? a_faire_par!( user['id'] ) : fait_par!( user['id'] )
  end

  def copie( cours_id, timeslot_id, date_due )
    nouveau_devoir = Devoir.create( cours_id: cours_id,
                                    type_devoir_id: type_devoir_id,
                                    timeslot_id: timeslot_id,
                                    contenu: contenu,
                                    date_due: date_due,
                                    temps_estime: temps_estime,
                                    enseignant_id: enseignant_id,
                                    date_creation: Time.now )

    resources.each do |resource|
      nouveau_devoir.add_resource resource
    end
  end

  def modifie( params )
    self.date_due = params['date_due']
    self.tmieslot_id = params['timeslot_id']
    self.type_devoir_id = params['type_devoir_id']
    self.contenu = params['contenu']
    self.temps_estime = params['temps_estime'] unless params['temps_estime'].nil?
    self.cours_id = params['cours_id'] unless params['cours_id'].nil?
    self.enseignant_id = params['enseignant_id'] unless params['enseignant_id'].nil?

    if params['resources']
      remove_all_resources

      params['resources'].each do |resource|
        add_resource( DataManagement::Accessors.create_or_get( Resource, name: resource['name'],
                                                                           hash: resource['hash'] ) )
      end
    end

    self.date_modification = Time.now

    save
  end
end

class TypeDevoir < Sequel::Model( :types_devoir )
  one_to_many :devoirs
end

class DevoirResource < Sequel::Model( :devoirs_resources )
end

class DevoirTodoItem < Sequel::Model( :devoir_todo_items )
  many_to_one :devoir
end
