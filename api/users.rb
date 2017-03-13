# -*- coding: utf-8 -*-

require_relative '../lib/data_management'

module CahierDeTextesApp
  class UsersAPI < Grape::API
    desc 'renvoi les infos de l\'utilisateur identifié'
    get '/current' do
      utilisateur = user_verbose

      parametres = UserParameters.where( uid: utilisateur[ :uid ] ).first
      parametres = UserParameters.create( uid: utilisateur[ :uid ] ) if parametres.nil?
      parametres.update( date_connexion: Time.now )
      parametres.save

      utilisateur[ 'parametrage_cahier_de_textes' ] = JSON.parse( parametres[:parameters] )

      all_matieres = Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere, '', expand: 'true' )

      utilisateur[ 'profils' ].each do |profil|
        if !profil['admin'] && %w(ENS).include?( profil['profil_id'] )
          profil['matieres'] = utilisateur['regroupements'].map do |regroupement|
            next if regroupement['etablissement_code'] != profil['etablissement_code_uai']
            next unless regroupement.key?( 'matiere_enseignee_id' )

            { id: regroupement['matiere_enseignee_id'],
              libelle_court: regroupement['matiere_libelle'],
              libelle_long: regroupement['matiere_libelle'] }
          end.flatten.compact.uniq

          profil['matieres'] = all_matieres if profil['matieres'].empty?
        elsif %w(DIR ELV).include?( profil['profil_id'] ) || profil['admin']
          profil['matieres'] = all_matieres
        end
      end
      utilisateur
    end

    desc 'met à jour les paramètres utilisateurs'
    params do
      requires :parametres, type: String
    end
    put '/current/parametres' do
      parametres = UserParameters.where( uid: user[:uid] ).first

      parametres.update( parameters: params[:parametres] )
      parametres.save

      user_verbose
    end
  end
end
