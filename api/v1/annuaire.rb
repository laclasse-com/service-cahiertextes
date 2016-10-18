# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    # API d'interfaçage avec l'annuaire
    class AnnuaireAPI < Grape::API
      format :json

      desc 'Renvoi la liste de toutes les matières'
      get '/matieres' do
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere, '', expand: 'true' )
      end

      desc 'Renvoi le détail d\'une matière'
      params do
        requires :id, desc: 'id de la matière'
      end
      get '/matieres/:id' do
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere, "#{CGI.escape( params[:id] )}", expand: 'false' )
      end

      desc 'retourne un établissement'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/etablissements/:uai' do
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_v2_etablissements, "#{params[:uai]}", {} )
      end

      desc 'retourne la liste des enseignants de l\'établissement'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/etablissements/:uai/enseignants' do
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_etablissement, "#{params[:uai]}/enseignants", expand: 'true' )
      end

      desc 'retourne la liste des regroupements de l\'établissement'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/etablissements/:uai/regroupements' do
        regroupements = Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_etablissement,
                                                                        "#{params[:uai]}/regroupements",
                                                                        expand: 'true' )

        regroupements.keys.each do |type|
          regroupements[ type ].each do |regroupement|
            regroupement[ 'libelle' ] ||= regroupement[ 'libelle_aaf' ]
          end
        end

        regroupements
      end

      desc 'Renvoi le détail d\'un regroupement'
      params do
        requires :id, desc: 'id du regroupement'
      end
      get '/regroupements/:id' do
        regroupement = Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_regroupement,
                                                                       "#{CGI.escape( params[:id] )}",
                                                                       expand: 'false' )
        regroupement['libelle'] = regroupement['libelle_aaf'] if regroupement['libelle'].nil?
        regroupement['libelle_aaf'] = regroupement['libelle'] if regroupement['libelle_aaf'].nil?

        regroupement
      end

      desc 'Renvoi le détail d\'un utilisateur'
      params do
        requires :id, desc: 'id de l\'utilisateur'
      end
      get '/users/:id' do
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_user,
                                                        "#{params[:id]}",
                                                        expand: 'true' )
      end

      desc 'Renvoi le détail d\'une liste d\'utilisateur'
      params do
        requires :ids, desc: 'tableau d\'ids des utilisateurs' # , type: Array do
        #   requires :id, type: String
        # end
      end
      get '/users/bulk/:ids' do
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_user_liste,
                                                        "#{params[:ids].split(',').join('_')}",
                                                        expand: 'true' )
      end
    end
  end
end
