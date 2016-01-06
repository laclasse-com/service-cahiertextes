# encoding: utf-8
# -*- coding: utf-8 -*-

require 'base64'
require 'cgi'
require 'openssl'

require 'laclasse/cross_app/sender'

require_relative '../config/options'

# Module d'interfaçage avec l'annuaire
module AnnuaireWrapper
  module User
    module_function

    # Service Utilisateur : init de la session et de son environnement
    def get( uid )
      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_user,
                                                      "#{uid}",
                                                      expand: 'true' )
    end

    # Liste des regroupements de l'utilisateur connecté
    def get_regroupements( uid )
      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_user,
                                                      "#{uid}/regroupements",
                                                      expand: 'true' )
    end
  end

  # fonctions relatives à l'établissement
  module Etablissement
    module_function

    # Liste des personnels d'un etablissement
    def get( uai )
      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_etablissement,
                                                      "#{uai}",
                                                      expand: 'true' )
    end

    # Liste des regroupements d'un établissement
    def get_regroupements( uai )
      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_etablissement,
                                                      "#{uai}/regroupements",
                                                      expand: 'true' )
    end

    # Liste des enseignants d'un établissement
    def get_enseignants( uai )
      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_etablissement,
                                                      "#{uai}/enseignants",
                                                      expand: 'true' )
    end

    module Regroupement
      module_function

      def search( uai, label )
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_regroupement,
                                                        '',
                                                        etablissement: uai,
                                                        nom: label,
                                                        expand: 'false' )
      end
    end

    module User
      module_function

      def search( uai, nom, prenom )
        Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_user,
                                                        '',
                                                        etablissement: uai,
                                                        nom: nom,
                                                        prenom: prenom,
                                                        expand: 'true' )
      end
    end
  end

  module Matiere
    module_function

    def query
      matieres = Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere,
                                                                 '',
                                                                 expand: 'true' )
      matieres << { 'id' => 'documentation', 'libelle_court' => nil, 'libelle_long' => 'CDI' }
    end

    def get( id )
      return { 'id' => 'documentation', 'libelle_court' => nil, 'libelle_long' => 'CDI' } if id == 'documentation'

      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere,
                                                      "#{CGI.escape( id )}",
                                                      expand: 'false' )
    end

    def search( label )
      return { 'id' => 'documentation', 'libelle_court' => nil, 'libelle_long' => 'CDI' } if label == 'CDI'

      Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_matiere,
                                                      "libelle/#{CGI.escape( label )}",
                                                      expand: 'false' )
    end
  end

  module Regroupement
    module_function

    def get( id )
      regroupement = Laclasse::CrossApp::Sender.send_request_signed( :service_annuaire_regroupement,
                                                                     "#{CGI.escape( id )}",
                                                                     expand: 'false' )
      regroupement['libelle'] = regroupement['libelle_aaf'] if regroupement['libelle'].nil?
      regroupement['libelle_aaf'] = regroupement['libelle'] if regroupement['libelle_aaf'].nil?

      regroupement
    end
  end
  
  module Log
    module_function
    
    def add( entry )
      Laclasse::CrossApp::Sender.post_request_signed( :service_annuaire_v2_logs, '', entry, {} )
    end
  end
end
