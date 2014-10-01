# -*- encoding: utf-8 -*-

module UserHelpers
  class HashIt
    def initialize( hash )
      hash.each do |k, v|
        instance_variable_set( "@#{k}", v )
        # create the getter
        self.class.send( :define_method, k, proc { instance_variable_get( "@#{k}" ) } )
        # create the setter
        # self.class.send( :define_method, "#{k}=", proc{ |val| instance_variable_set( "@#{k}", val ) } )
      end
    end
  end

  class HashedUser < HashIt
    def is?( profil )
      # FIXME
      profils = Annuaire.get_user( @uid )['profils']
      @ENTPersonProfils.include? "#{profil}:#{profils[0]['uai']}"
    end

    def full( env )
      utilisateur = env['rack.session'][:current_user]

      extra = Annuaire.get_user( utilisateur[ 'uid' ] )
      utilisateur[ 'profils' ] = extra['profils'].map do |profil|
        # renommage de champs
        profil['type'] = profil['profil_id']
        profil['uai'] = profil['etablissement_code_uai']
        profil['etablissement'] = profil['etablissement_nom']
        profil['nom'] = profil['profil_nom']

        # calcule du droit d'admin, true pour les TECH et les ADM
        profil['admin'] = extra['roles'].select { |r| r['etablissement_code_uai'] == profil['etablissement_code_uai'] && ( r['role_id'] == 'TECH' || r['role_id'].match('ADM.*') ) }.length > 0

        profil['classes'] = Annuaire.get_etablissement_regroupements( profil['uai'] ) if profil['type'] == 'EVS'
        profil
      end
      utilisateur[ 'enfants' ] = extra [ 'enfants' ]

      regroupements_annuaire = Annuaire.get_user_regroupements( utilisateur[ 'uid' ] )
      utilisateur[ 'classes' ] = regroupements_annuaire[ 'classes' ]
                                 .concat( regroupements_annuaire['groupes_eleves'] )
                                 .concat( regroupements_annuaire['groupes_libres'] )
                                 .map do |regroupement|
        if regroupement.key? 'groupe_id'
          regroupement['type'] = 'groupe'
          regroupement['classe_id'] = regroupement['groupe_id']
          regroupement['classe_libelle'] = regroupement['groupe_libelle']
        else
          regroupement['type'] = 'classe'
        end
        regroupement
      end

      parametres = UserParameters.where( uid: utilisateur[ 'uid' ] ).first
      parametres = UserParameters.create( uid: utilisateur[ 'uid' ] ) if parametres.nil?
      parametres.update( date_connexion: Time.now )
      parametres.save

      utilisateur['parametrage_cahier_de_textes'] = JSON.parse( parametres[:parameters] )

      utilisateur
    end
  end

  def user
    HashedUser.new env['rack.session'][:current_user]
  end
end
