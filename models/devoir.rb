# -*- coding: utf-8 -*-

class Devoir < Sequel::Model( :devoirs )
  many_to_many :ressources
  many_to_one :creneau_emploi_du_temps
  many_to_one :type_devoir
  one_to_many :devoir_todo_items
  many_to_one :cours

  def to_deep_hash( user = nil )
    h = to_hash

    h[:ressources] = ressources.map(&:to_hash)

    h[:creneau_emploi_du_temps] = creneau_emploi_du_temps.to_hash
    h[:cours] = cours.to_hash

    h[:devoir_todo_items] = devoir_todo_items
    h[:devoir_todo_items] = [] if user.nil?
    h[:devoir_todo_items].select! { |dti| dti[:eleve_id] == user['id'] } unless user.nil?

    h[:fait] = user.nil? ? false : fait_par?( user['id'] )
    h[:date_fait] = h[:fait] ? fait_le( user['id'] ) : nil

    h
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

  def copie( cours_id, creneau_emploi_du_temps_id, date_due )
    nouveau_devoir = Devoir.create( cours_id: cours_id,
                                    type_devoir_id: type_devoir_id,
                                    creneau_emploi_du_temps_id: creneau_emploi_du_temps_id,
                                    contenu: contenu,
                                    date_due: date_due,
                                    temps_estime: temps_estime,
                                    date_creation: Time.now )

    ressources.each do |ressource|
      nouveau_devoir.add_ressource ressource
    end
  end

  def modifie( params )
    self.date_due = params[:date_due]
    self.creneau_emploi_du_temps_id = params[:creneau_emploi_du_temps_id]
    self.type_devoir_id = params[:type_devoir_id]
    self.contenu = params[:contenu]
    self.temps_estime = params[:temps_estime] unless params[:temps_estime].nil?
    self.cours_id = params[:cours_id] unless params[:cours_id].nil?
    self.enseignant_id = params[:enseignant_id] unless params[:enseignant_id].nil?

    if params[:ressources]
      remove_all_ressources

      params[:ressources].each do |ressource|
        add_ressource( DataManagement::Accessors.create_or_get( Ressource, name: ressource['name'],
                                                                           hash: ressource['hash'] ) )
      end
    end

    self.date_modification = Time.now

    save
  end
end

class TypeDevoir < Sequel::Model( :types_devoir )
  one_to_many :devoirs
end

class DevoirRessource < Sequel::Model( :devoirs_ressources )
end

class DevoirTodoItem < Sequel::Model( :devoir_todo_items )
  many_to_one :devoir
end
