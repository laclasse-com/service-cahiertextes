# -*- coding: utf-8 -*-

class Import < Sequel::Model( :imports )
  many_to_one :etablissements
end
