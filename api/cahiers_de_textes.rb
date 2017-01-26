module CahierDeTextesAPI
  class CahiersDeTextesAPI < Grape::API
    desc 'renvoi le cahier de textes d\'un regroupement'
    params do
      requires :regroupement_id
      requires :debut_annee_scolaire
      requires :fin_annee_scolaire
      requires :label
    end
    post '/' do
      ct = DataManagement::Accessors.create_or_get( CahierDeTextes,
                                                    regroupement_id: params[:regroupement_id])
      ct.update( debut_annee_scolaire: params[:debut_annee_scolaire],
                 fin_annee_scolaire: params[:fin_annee_scolaire],
                 label: params[:label] )
      ct.save

      ct
    end

    desc 'mass creation of cahiers de textes'
    params do
      requires :cahiers_de_textes, type: Array
    end
    post '/bulk' do
      params[:cahiers_de_textes].map do |ct|
        new_ct = DataManagement::Accessors.create_or_get( CahierDeTextes,
                                                          regroupement_id: ct[:regroupement_id])
        new_ct.update( debut_annee_scolaire: ct[:debut_annee_scolaire],
                       fin_annee_scolaire: ct[:fin_annee_scolaire],
                       label: ct[:label] )
        new_ct.save

        new_ct
      end
    end
  end
end
