# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    # API d'accès aux devoirs
    # Utilisée par les :
    #   - élèves pour consultation et gestion todo-list
    #   - enseignants pour consultation et édition
    #   - principaux pour consultation
    class DevoirsAPI < Grape::API

      desc 'renvoi tous les devoirs concernant l\'utilisateur durant la période donnée'
      params {
        optional :debut, type: Date
        optional :fin, type: Date
        optional :uid
      }
      get '/' do
        if params[:uid]
          user_annuaire = Annuaire.get_user( user.uid )
          if user_annuaire['profils'].select { |p| p['actif'] }.first['profil_id'] == 'TUT' && !( user_annuaire['enfants'].select { |e| e['enfant']['id_ent'] == params[:uid] }.first.nil? )
            regroupements_annuaire = Annuaire.get_user_regroupements( params[:uid] )
          else
            error!( '401 Unauthorized', 401 )
          end
        else
          regroupements_annuaire = Annuaire.get_user_regroupements( user.uid )
        end

        regroupements_ids = regroupements_annuaire['classes']
                            .concat( regroupements_annuaire['groupes_eleves'] )
                            .concat( regroupements_annuaire['groupes_libres'] )
                            .reject { |regroupement| regroupement['etablissement_code'] != params[:uai] if params[:uai] }
                            .map do |regroupement|
          if regroupement.key? 'classe_id'
            regroupement['classe_id']
          elsif regroupement.key? 'groupe_id'
            regroupement['groupe_id']
          elsif regroupement.key? 'id'
            regroupement['id']
          end
        end
                            .uniq

        if params[:debut].nil? || params[:fin].nil?
          devoirs = Devoir
                    .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id)
                    .where( regroupement_id: regroupements_ids )
                    .where( deleted: false )
        else
          devoirs = Devoir
                    .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id)
                    .where( regroupement_id: regroupements_ids )
                    .where( deleted: false )
                    .where( date_due: params[:debut] .. params[:fin] )
        end

        devoirs.map do |devoir|
          hash = devoir.to_deep_hash
          hash[:devoir_todo_items].select! { |dti| dti[:eleve_id] == user.uid } unless user.nil?
          hash[:devoir_todo_items] = [] if user.nil?

          hash[:fait] = user.nil? ? false : devoir.fait_par?( user.uid )
          hash[:date_fait] = hash[:fait] ? devoir.fait_le( user.uid ) : nil

          # BUG: to_deep_hash casse les hash des ressources
          hash[:ressources] = devoir.ressources.map do |ressource|
            ressource.to_hash
          end

          hash
        end
      end

      desc 'renvoi le détail d\'un devoir'
      params {
        requires :id
      }
      get '/:id' do
        devoir = Devoir[ params[:id] ]
        if devoir.nil? || ( devoir.deleted && devoir.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )
          error!( 'Devoir inconnu', 404 )
        else
          hash = devoir.to_deep_hash
          hash[:devoir_todo_items].select! { |dti| dti[:eleve_id] == user.uid } unless user.nil?
          hash[:devoir_todo_items] = [] if user.nil?

          hash[:fait] = user.nil? ? false : devoir.fait_par?( user.uid )
          hash[:date_fait] = hash[:fait] ? devoir.fait_le( user.uid ) : nil

          # BUG: to_deep_hash casse les hash des ressources
          hash[:ressources] = devoir.ressources.map do |ressource|
            ressource.to_hash
          end

          hash
        end
      end

      desc 'renseigne un devoir'
      params {
        requires :type_devoir_id
        requires :contenu
        requires :creneau_emploi_du_temps_id
        requires :date_due, type: Date

        optional :cours_id
        optional :regroupement_id
        optional :ressources
        optional :temps_estime
      }
      post  do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        if CreneauEmploiDuTemps[ params[:creneau_emploi_du_temps_id] ].nil?
          error!( 'Paramètres invalides', 404 )
        else
          devoir = Devoir.create( type_devoir_id: params[:type_devoir_id],
                                  creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
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
              cahier_de_textes = CahierDeTextes.create( date_creation: Time.now,
                                                        regroupement_id: params[:regroupement_id] ) if cahier_de_textes.nil?

              cours = Cours.create( enseignant_id: user.uid,
                                    cahier_de_textes_id: cahier_de_textes.id,
                                    creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                    date_cours: params[:date_due],
                                    date_creation: Time.now,
                                    contenu: '' )
            end
            devoir.update( cours_id: cours.id )
          end

          # 3. traitement des ressources
          params[:ressources] && params[:ressources].each do
            |ressource|

            STDERR.puts "Cette ressource est pourrie : #{ressource}" unless ressource['hash'].include? '_'

            devoir.add_ressource( Ressource.create( name: ressource['name'],
                                                    hash: ressource['hash'] ) )
          end

          hash = devoir.to_deep_hash
          hash[:devoir_todo_items] = []

          # BUG: to_deep_hash casse les hash des ressources
          hash[:ressources] = devoir.ressources.map do |ressource|
            ressource.to_hash
          end

          hash
        end
      end

      desc 'modifie un devoir'
      params {
        requires :id
        requires :type_devoir_id
        requires :contenu
        requires :creneau_emploi_du_temps_id
        requires :date_due, type: Date

        optional :cours_id
        optional :ressources
        optional :temps_estime
      }
      put '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        devoir = Devoir[ params[:id] ]
        if devoir.nil?
          error!( 'Devoir inconnu', 404 )
        else

          devoir.date_due = params[:date_due] if devoir.date_due != params[:date_due]
          devoir.creneau_emploi_du_temps_id = params[:creneau_emploi_du_temps_id] if devoir.creneau_emploi_du_temps_id != params[:creneau_emploi_du_temps_id]

          devoir.type_devoir_id = params[:type_devoir_id] if devoir.type_devoir_id != params[:type_devoir_id]
          devoir.contenu = params[:contenu] if devoir.contenu != params[:contenu]
          devoir.temps_estime = params[:temps_estime] if devoir.temps_estime != params[:temps_estime]

          devoir.update( cours_id: params[:cours_id] ) if params[ :cours_id ]

          devoir.remove_all_ressources if params[:ressources]
          params[:ressources].each do |ressource|

            STDERR.puts "Cette ressource est pourrie : #{ressource}" unless ressource['hash'].include? '_'

            devoir.add_ressource( Ressource.create( name: ressource['name'],
                                                    hash: ressource['hash'] ) )
          end if params[:ressources]

          devoir.date_modification = Time.now
          devoir.save

          hash = devoir.to_deep_hash
          hash[:devoir_todo_items] = []

          # BUG: to_deep_hash casse les hash des ressources
          hash[:ressources] = devoir.ressources.map do |ressource|
            ressource.to_hash
          end

          hash
        end
      end

      desc 'copie un devoir pour le rattacher à une autre SP et un créneau et une date_due différente'
      params {
        requires :id
        requires :cours_id
        requires :creneau_emploi_du_temps_id
        requires :date_due
      }
      put '/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        devoir = Devoir[ params[:id] ]

        nouveau_devoir = Devoir.create( cours_id: params[:cours_id],
                                        type_devoir_id: devoir[:type_devoir_id],
                                        creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                        contenu: devoir[:contenu],
                                        date_due: params[:date_due],
                                        temps_estime: devoir[:temps_estime],
                                        date_creation: Time.now )

        devoir.ressources.each do |ressource|

          STDERR.puts "Cette ressource est pourrie : #{ressource}" unless ressource['hash'].include? '_'

          nouveau_devoir.add_ressource ressource
        end

        nouveau_devoir
      end

      desc 'marque un devoir comme fait'
      params {
        requires :id
      }
      put '/:id/fait' do
        error!( '401 Unauthorized', 401 ) unless user.is? 'ELV'

        devoir = Devoir[ params[:id] ]
        devoir.fait_par?( user.uid ) ? devoir.a_faire_par!( user.uid ) : devoir.fait_par!( user.uid )

        hash = devoir.to_deep_hash
        hash[:devoir_todo_items] = [] if user.nil?
        hash[:devoir_todo_items].select! { |dti| dti[:eleve_id] == user.uid } unless user.nil?

        hash[:fait] = user.nil? ? false : devoir.fait_par?( user.uid )
        hash[:date_fait] = hash[:fait] ? devoir.fait_le( user.uid ) : nil

        # BUG: to_deep_hash casse les hash des ressources
        hash[:ressources] = devoir.ressources.map do |ressource|
          ressource.to_hash
        end

        hash
      end

      desc 'marque un devoir comme éffacé et inversement'
      params {
        requires :id
      }
      delete '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.admin?

        devoir = Devoir[ params[:id] ]

        unless devoir.nil?
          devoir.update( deleted: !devoir.deleted, date_modification: Time.now )
          devoir.save

          hash = devoir.to_deep_hash
          hash[:devoir_todo_items].select! { |dti| dti[:eleve_id] == user.uid } unless user.nil?
          hash[:devoir_todo_items] = [] if user.nil?

          hash[:fait] = user.nil? ? false : devoir.fait_par?( user.uid )
          hash[:date_fait] = hash[:fait] ? devoir.fait_le( user.uid ) : nil

          # BUG: to_deep_hash casse les hash des ressources
          hash[:ressources] = devoir.ressources.map do |ressource|
            ressource.to_hash
          end

          hash
        end
      end
    end
  end
end
