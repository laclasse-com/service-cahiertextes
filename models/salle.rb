# -*- coding: utf-8 -*-

class Salle < Sequel::Model( :salle )
  many_to_one :etablissement
end
