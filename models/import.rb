# -*- coding: utf-8 -*-

class Import < Sequel::Model( :imports )
  many_to_one :etablissements
  one_to_many :failed_identifications, class: :FailedIdentification
end
