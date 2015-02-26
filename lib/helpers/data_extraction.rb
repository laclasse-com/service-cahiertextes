# -*- coding: utf-8 -*-

require_relative '../data_management'

module CahierDeTextesApp
  module Helpers
    module DataExtraction
      def emploi_du_temps( debut, fin, regroupements_ids, eleve_id )
        DataManagement::EmploiDuTemps.get( debut, fin, regroupements_ids, eleve_id )
      end
    end
  end
end
