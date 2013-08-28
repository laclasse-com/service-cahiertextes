# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EnseignantAPI < Grape::API
    format :json

    resource :enseignant do

      resource :emploi_du_temps do
        # TODO
      end

    end

  end
end
