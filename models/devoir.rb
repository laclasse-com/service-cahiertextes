# -*- coding: utf-8 -*-

class Devoir < Sequel::Model( :devoir )
  many_to_many :ressource
end

class TypeDevoir < Sequel::Model( :type_devoir )

end

class DevoirRessource < Sequel::Model( :devoir_ressource )

end

class DevoirTodoItem < Sequel::Model( :devoir_todo_item )
  many_to_one :devoir
end
