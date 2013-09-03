# -*- coding: utf-8 -*-

class Devoir < Sequel::Model( :devoirs )
  many_to_many :ressources
  one_to_many :devoir_todo_items
  many_to_one :type_devoir

  def fait_par( eleve_id )
    add_devoir_todo_items( eleve_id: eleve_id, date_fait: Time.now )
  end
  def fait_par?( eleve_id )
    # FIXME: peut sûrement mieux faire
    devoir_todo_items_dataset.where(eleve_id: eleve_id).count > 0
  end
  def plus_fait_par( eleve_id )
    # FIXME: peut sûrement mieux faire
    devoir_todo_items_dataset.where(eleve_id: eleve_id).destroy
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
