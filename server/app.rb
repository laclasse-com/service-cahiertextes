# -*- coding: utf-8 -*-

require 'rubygems'
require 'bundler/setup'

require 'grape'
require 'nokogiri'
require 'sequel'
require 'sequel/extensions/migration'

require './models'
require './pronote'

module CahierDeTexte
  class API < Grape::API
    version 'v0', using: :header, vendor: 'laclasse.com'
    format :json

    helpers do
      def current_user
        # TODO: @current_user ||= User.authorize!(env)
        true
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    resource :etablissement do

      resource :tranche_horaire do
        # GET http://localhost:9292/etablissement/tranche_horaire/3
        desc 'Renvoi une tranche horaire'
        params do
          requires :label, type: String, desc: 'label de la tranche horaire'
        end
        route_param :label do
          get do
            TrancheHoraire.filter(:label => params[:label])  # FIXME: only_time not enforced in json output
          end
        end
      end

      resource :salle do
        # GET http://localhost:9292/etablissement/salle/15519
        desc 'Renvoi une salle'
        params do
          requires :identifiant, type: String, desc: 'identifiant de la salle'
        end
        route_param :identifiant do
          get do
            Salle.filter(identifiant: params[:identifiant])
          end
        end
      end

    end

  end
end

ProNote.load_XML(File.open('mocks/Edt_To_LaclasseCom_0134567A_Enclair.xml'),
                 File.open('mocks/ExportEmploiDuTemps.xsd'))
