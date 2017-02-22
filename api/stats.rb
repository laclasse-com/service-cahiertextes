# -*- coding: utf-8 -*-

module CahierDeTextesApp
  class StatsAPI < Grape::API
    desc 'return some statistics'
    params do
      requires :from, type: Date
      requires :until, type: Date
    end
    get '/:from/:until' do
      { creneaux_emplois_du_temps: CreneauEmploiDuTemps.where( date_creation: params[:from]..params[:until] ).count,
        sequences_pedagogiques: Cours.where( date_creation: params[:from]..params[:until] ).count,
        devoirs: Devoir.where( date_creation: params[:from]..params[:until] ).count }
    end
  end
end
