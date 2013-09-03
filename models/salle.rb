# -*- coding: utf-8 -*-

class Salle < Sequel::Model( :salles )
  many_to_one :etablissements
end
