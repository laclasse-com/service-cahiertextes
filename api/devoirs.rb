# -*- coding: utf-8 -*-

module CahierDeTextesApp
  # API d'accès aux devoirs
  # Utilisée par les :
  #   - élèves pour consultation et gestion todo-list
  #   - enseignants pour consultation et édition
  #   - principaux pour consultation
  class DevoirsAPI < Grape::API
    desc 'renvoi tous les devoirs concernant l\'utilisateur durant la période donnée'
    params do
      requires :debut, type: Date
      requires :fin, type: Date

      optional :uid, type: String
      optional :uai, type: String
    end
    get '/' do
      uid = params[:uid] ? params[:uid] : user['id']

      if params[:uid]
        error!( '401 Unauthorized', 401 ) unless user['profiles'].select { |p| p['active'] }.first['type'] == 'TUT' && !user['children'].find { |e| e['child_id'] == params[:uid] }.nil?
      end

      Devoir.association_join(:creneau_emploi_du_temps)
            .select_append( :devoirs__id___id )
            .where( devoirs__deleted: false )
            .where( regroupement_id: user_regroupements_ids )
            .where( date_due: params[:debut] .. params[:fin] )
            .all
            .map { |devoir| devoir.to_deep_hash( uid: uid ) }
    end

    desc 'renvoi le détail d\'un devoir'
    params do
      requires :id
    end
    get '/:id' do
      devoir = Devoir[ params[:id] ]

      error!( 'Devoir inconnu', 404 ) if devoir.nil? || ( devoir.deleted && devoir.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

      devoir.to_deep_hash( user )
    end

    desc 'renseigne un devoir'
    params do
      requires :type_devoir_id
      requires :contenu
      requires :creneau_emploi_du_temps_id
      requires :date_due, type: Date

      optional :cours_id
      optional :regroupement_id
      optional :ressources
      optional :temps_estime
    end
    post  do
      user_needs_to_be( %w[ ENS DOC ] )

      error!( 'Créneau invalide', 409 ) if CreneauEmploiDuTemps[ params[:creneau_emploi_du_temps_id] ].nil?

      devoir = Devoir.create( type_devoir_id: params[:type_devoir_id],
                              creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                              enseignant_id: user['id'],
                              contenu: params[:contenu],
                              date_due: params[:date_due],
                              temps_estime: params[:temps_estime],
                              date_creation: Time.now )

      if params[ :cours_id ] && !params[ :cours_id ].nil?
        devoir.update( cours_id: params[:cours_id] )
      else
        cours = Cours.where( creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id] )
                     .where( date_cours: params[:date_due] )
                     .where( deleted: false )
                     .first
        if cours.nil?
          cahier_de_textes = CahierDeTextes.where( regroupement_id: params[:regroupement_id] ).first
          cahier_de_textes = CahierDeTextes.create( date_creation: Time.now, regroupement_id: params[:regroupement_id] ) if cahier_de_textes.nil?

          cours = Cours.create( enseignant_id: user['id'],
                                cahier_de_textes_id: cahier_de_textes.id,
                                creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                date_cours: params[:date_due],
                                date_creation: Time.now,
                                contenu: '' )
        end
        devoir.update( cours_id: cours.id )
      end

      devoir.modifie( params )

      devoir.to_deep_hash
    end

    desc 'modifie un devoir'
    params do
      requires :id
      requires :type_devoir_id
      requires :contenu
      requires :creneau_emploi_du_temps_id
      requires :date_due, type: Date

      optional :cours_id
      optional :ressources
      optional :temps_estime
    end
    put '/:id' do
      user_needs_to_be( %w[ ENS DOC ] )

      devoir = Devoir[ params[:id] ]
      error!( 'Devoir inconnu', 404 ) if devoir.nil?
      params[:enseignant_id] = user['id']

      devoir.modifie( params )

      devoir.to_deep_hash
    end

    desc 'copie un devoir pour le rattacher à une autre SP et un créneau et une date_due différente'
    params do
      requires :id
      requires :cours_id
      requires :creneau_emploi_du_temps_id
      requires :date_due
    end
    put '/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due' do
      user_needs_to_be( %w[ ENS DOC ] )

      devoir = Devoir[ params[:id] ]
      error!( 'Devoir inconnu', 404 ) if devoir.nil?

      devoir.copie( params[:cours_id], params[:creneau_emploi_du_temps_id], params[:date_due] )

      devoir
    end

    desc 'marque un devoir comme fait'
    params do
      requires :id
    end
    put '/:id/fait' do
      user_needs_to_be( %w( ELV ) )

      devoir = Devoir[ params[:id] ]
      error!( 'Devoir inconnu', 404 ) if devoir.nil?

      devoir.toggle_fait( user )

      devoir.to_deep_hash( user )
    end

    desc 'marque un devoir comme éffacé et inversement'
    params do
      requires :id
    end
    delete '/:id' do
      user_needs_to_be( %w[ ENS DOC ] )

      devoir = Devoir[ params[:id] ]
      error!( 'Devoir inconnu', 404 ) if devoir.nil?

      devoir.toggle_deleted

      devoir.to_deep_hash( user )
    end
  end
end
