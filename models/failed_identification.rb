# -*- coding: utf-8 -*-

class FailedIdentification < Sequel::Model( :failed_identifications )
  many_to_one :imports
end
