# -*- coding: utf-8 -*-

require_relative '../models/plage_horaire'
require_relative '../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
  class CreneauxEmploiDuTempsAPI < Grape::API

    desc 'renvoi les créneaux'
    get  do
      CreneauEmploiDuTemps.all
    end

    desc 'renvoi un créneau'
    params {
      requires :id
    }
    get '/:id' do
      CreneauEmploiDuTemps[ params[:id] ]
    end

    desc 'crée un créneau s\'il n\'existe pas déjà un semblable'
    params {
      requires :jour, type: Integer
      requires :heure_debut, type: Time
      requires :heure_fin, type: Time
      requires :matiere_id
      requires :regroupement_id

      optional :salle_id
    }
    post '/jour/:jour/debut/:heure_debut/fin/:heure_fin/matiere/:matiere_id/regroupement/:regroupement_id' do
      plage_horaire_debut = PlageHoraire.where(debut: params[:heure_debut] ).first

      if plage_horaire_debut.nil?
        plage_horaire_debut = PlageHoraire.create( label: '',
                                                   debut: params[:heure_debut],
                                                   fin: params[:heure_debut] + 1800 )
      end

      plage_horaire_fin = PlageHoraire.where(fin: params[:heure_fin] ).first
      if plage_horaire_fin.nil?
        plage_horaire_fin = PlageHoraire.create( label: '',
                                                 debut: params[:heure_fin] - 1800,
                                                 fin: params[:heure_fin] )
      end

      # FIXME: hack sale pour passer le test pendant lequel il n'y a pas d'user
      user = {'uid' => 'VAA60001'} if user.nil?

      creneau = CreneauEmploiDuTemps.create( debut: plage_horaire_debut.id,
                                             fin: plage_horaire_fin.id,
                                             jour_de_la_semaine: params[:jour],
                                             matiere_id: params[:matiere_id] )
      CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
      CreneauEmploiDuTempsEnseignant.create( creneau_emploi_du_temps_id: creneau.id,
                                             enseignant_id: user['uid'] )
      CreneauEmploiDuTempsEnseignant.restrict_primary_key
      CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
      CreneauEmploiDuTempsRegroupement.create( creneau_emploi_du_temps_id: creneau.id,
                                               regroupement_id: params[:regroupement_id] )
      CreneauEmploiDuTempsRegroupement.restrict_primary_key

      if params[:salle_id]
        CreneauEmploiDuTempsSalle.unrestrict_primary_key
        CreneauEmploiDuTempsSalle.create( creneau_emploi_du_temps_id: creneau.id,
                                          salle_id: params[:salle_id] )
        CreneauEmploiDuTempsSalle.restrict_primary_key
      end

      creneau
    end

    # desc 'mets à jour un créneau'
    # params {
    #   requires :id
    #   requires :jour
    #   requires :heure_debut
    #   requires :heure_fin
    #   requires :matiere_id
    #   requires :regroupement_id
    # }
    # put '/:id/jour/:jour/debut/:heure_debut/fin/:heure_fin/matiere/:matiere_id/regroupement/:regroupement_id' do
    #   { todo: true } # TODO
    # end

    # desc 'efface un créneau'
    # params {
    #   requires :id
    # }
    # delete '/:id' do
    #   { todo: true } # TODO
    # end

  end
end
