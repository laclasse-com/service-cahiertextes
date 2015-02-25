# encoding: utf-8

module Laclasse
  module Helpers
    module Authentication
      def logged?
        LOGGER.info 'Yeah yeah you are logged *wink*'
        true
      end
    end
  end
end

module AnnuaireWrapper
  def get_etablissement( _uai )
    { 'classes' => [ { 'etablissement_code' => 'Test',
                       'classe_id' => 1 },
                     { 'etablissement_code' => 'Test',
                       'classe_id' => 2 },
                     { 'etablissement_code' => 'Invalid',
                       'classe_id' => 3 } ],
      'groupes_eleves' => [ { 'etablissement_code' => 'Test',
                              'groupe_id' => 4 },
                            { 'etablissement_code' => 'Invalid',
                              'groupe_id' => 5 } ],
      'groupes_libres' => [  ] }
  end
end
