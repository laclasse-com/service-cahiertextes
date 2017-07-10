# -*- coding: utf-8 -*-

require_relative '../lib/data_management'

module CahierDeTextesApp
  class UsersAPI < Grape::API
    desc 'renvoi les infos de l\'utilisateur identifié'
    get '/current' do
      # utilisateur = user # _verbose
      utilisateur = JSON.parse( RestClient::Request.execute( method: :get,
                                                             url: "#{URL_ENT}/api/users/#{env['rack.session']['uid']}",
                                                             user: ANNUAIRE[:app_id],
                                                             password: ANNUAIRE[:api_key] ) )
      p utilisateur
      parametres = UserParameters.where( uid: utilisateur[ 'id' ] ).first
      parametres = UserParameters.create( uid: utilisateur[ 'id' ] ) if parametres.nil?
      parametres.update( date_connexion: Time.now )
      parametres.save

      utilisateur[ 'parametrage_cahier_de_textes' ] = JSON.parse( parametres[:parameters] )

      all_matieres = JSON.parse( RestClient::Request.execute( method: :get,
                                                              url: "#{URL_ENT}/api/subjects",
                                                              user: ANNUAIRE[:app_id],
                                                              password: ANNUAIRE[:api_key] ) )
      # Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere, '', expand: 'true' )

      # utilisateur[ 'profils' ].each do |profil|
      #   if !profil['admin'] && %w[ENS].include?( profil['profil_id'] )
      #     profil['matieres'] = utilisateur['regroupements'].map do |regroupement|
      #       next if regroupement['etablissement_code'] != profil['etablissement_code_uai']
      #       next unless regroupement.key?( 'matiere_enseignee_id' )

      #       { id: regroupement['matiere_enseignee_id'],
      #         libelle_court: regroupement['matiere_libelle'],
      #         libelle_long: regroupement['matiere_libelle'] }
      #     end.flatten.compact.uniq

      #     profil['matieres'] = all_matieres if profil['matieres'].empty?
      #   elsif %w[DIR ELV].include?( profil['profil_id'] ) || profil['admin']
      #     profil['matieres'] = all_matieres
      #   end
      # end

      utilisateur['enfants'] = utilisateur['children']
      utilisateur[ 'profils' ] = utilisateur['profiles'].map do |profil|
        profil['matieres'] = all_matieres
        p profil['active']
        profil
      end
      # utilisateur[ 'profil_actif' ] = utilisateur['profils'].find { |profil| profil['active'] }

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
