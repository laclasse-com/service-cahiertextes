# encoding: utf-8

module UserHelpers
  @@user = nil

  class HashIt
    def initialize( hash )
      hash.each do |k, v|
        instance_variable_set( "@#{k}", v )
        # create the getter
        self.class.send(:define_method, k, proc { instance_variable_get( "@#{k}" ) } )
        # create the setter
        # self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
      end
    end
  end

  class HashedUser < HashIt
    def is?( profil )
      # FIXME
      profils = Annuaire.get_user( @uid )['profils']
      @ENTPersonProfils.include? "#{profil}:#{profils[0]['uai']}"
    end
  end

  def user
    test_user = { 'user'                      => 'gwenhael',
                  'idEnt'                     => 'Laclasse',
                  'ENT_id'                    => '1182',
                  'uid'                       => 'VAC65103',
                  'LaclasseNom'               => 'Le Moine',
                  'LaclassePrenom'            => 'Gwenhael',
                  'LaclasseCivilite'          => 'Mr',
                  'ENTPersonStructRattachRNE' => '0699999Z',
                  'ENTStructureNomCourant'    => 'ERASME',
                  'ENTPersonProfils'          => 'DIR:0699999Z;ENS:0699999Z;ELV:0699999Z;DIR:0134567A',
                  'ENTPersonRoles'            => 'DIR_ETB:0699999Z:1' }
    @@user = HashedUser.new test_user

    @@user
  end
end

def eleve

end
