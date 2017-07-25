# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Api
      module CahiersDeTextes
        def self.registered( app )
          app.post '/api/cahiers_de_textes/?' do
            # param :regroupement_id, String, required: true
            # param :debut_annee_scolaire, Date, required: true
            # param :fin_annee_scolaire, Date, required: true
            # param :label, String, required: true

            user_needs_to_be( %w[ ADM DIR ] )

            ct = DataManagement::Accessors.create_or_get( CahierDeTextes,
                                                          regroupement_id: params['regroupement_id'])
            ct.update( debut_annee_scolaire: params['debut_annee_scolaire'],
                       fin_annee_scolaire: params['fin_annee_scolaire'],
                       label: params['label'] )
            ct.save

            json( ct )
          end

          app.post '/api/cahiers_de_textes/bulk/?' do
            user_needs_to_be( %w[ ADM DIR ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            json( body['cahiers_de_textes'].map do |ct|
                    new_ct = DataManagement::Accessors.create_or_get( CahierDeTextes,
                                                                      regroupement_id: ct['regroupement_id'])
                    new_ct.update( debut_annee_scolaire: ct['debut_annee_scolaire'],
                                   fin_annee_scolaire: ct['fin_annee_scolaire'],
                                   label: ct['label'] )
                    new_ct.save

                    new_ct.to_hash
                  end )
          end
        end
      end
    end
  end
end
