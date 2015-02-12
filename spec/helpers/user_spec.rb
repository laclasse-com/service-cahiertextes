# -*- coding: utf-8 -*-

require 'spec_helper'

describe CahierDeTextesApp::Helpers::User do
  subject do
    Class.new { include CahierDeTextesApp::Helpers::User }
  end

  it 'Checks that the user is admin in a given etablissement when he have a TECH role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH' } ] } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin_in_etablissement?( 'Test' ) ).to be true
  end

  it 'Checks that the user is admin in a given etablissement when he have a ADM_* role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'ADM_ETB'
                                            } ] } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin_in_etablissement?( 'Test' ) ).to be true
  end

  it 'Checks that the user is NOT admin in a given etablissement when he have another role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'Pirate'
                                            } ] } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin_in_etablissement?( 'Test' ) ).to be false
  end

  it 'Checks that the user is admin through profil_actif' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH'
                                            } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_admin? ).to be true
  end

  it 'Checks that the user is within the list of the required profile' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'profil_actif' => { 'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_a?( %w( GOOD ) ) ).to be true
  end

  it 'Checks that the user is within the list of required multiple profiles' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'profil_actif' => { 'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_a?( %w( BAD BAD2 GOOD ) ) ).to be true
  end

  it 'Checks that the user is NOT within the list of required multiple profiles' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'profil_actif' => { 'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_is_a?( %w( BAD2 BAD3 ) ) ).to be false
  end

  it 'Checks that the user is within the list of required multiple profiles or admin' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], true ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), false ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), true ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), true ) ).to be true
  end

  it 'Checks that the user is within the list of required multiple profiles or admin' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'Lambda' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'GOOD' } } }
          end
        end
      end
    end

    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( [], true ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), false ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( GOOD ), true ) ).to be true
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), false ) ).to be false
    expect( subject.new.user_belongs_to_profils_or_is_admin?( %w( BAD ), true ) ).to be false
  end

  it 'Extract the list of user\'s own regroupements\' IDs as ENS' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { user_detailed: { 'classes' => [ { 'etablissement_code' => 'Test',
                                                'classe_id' => 1 },
                                              { 'etablissement_code' => 'Test',
                                                'classe_id' => 2 },
                                              { 'etablissement_code' => 'Invalid',
                                                'classe_id' => 9 } ],
                               'groupes_eleves' => [ { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 11 },
                                                     { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 99 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 12 } ],
                               'groupes_libres' => [ { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 999 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 101 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 102 } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'ENS' }
                             } }
          end
        end
      end
    end

    expect( subject.new.user_regroupements_ids ).to eq [ 1, 2, 11, 12, 101, 102 ]
  end

  it 'Process the user profile as the CT needs it to be' do
    module CahierDeTextesApp
      module Helpers
        module User
          def user
            { uid: 'VAA00000',
              user_detailed: { 'classes' => [ { 'etablissement_code' => 'Test',
                                                'classe_id' => 1 },
                                              { 'etablissement_code' => 'Test',
                                                'classe_id' => 2 },
                                              { 'etablissement_code' => 'Invalid',
                                                'classe_id' => 9 } ],
                               'groupes_eleves' => [ { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 11 },
                                                     { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 99 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 12 } ],
                               'groupes_libres' => [ { 'etablissement_code' => 'Invalid',
                                                       'groupe_id' => 999 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 101 },
                                                     { 'etablissement_code' => 'Test',
                                                       'groupe_id' => 102 } ],
                               'roles' => [ { 'etablissement_code_uai' => 'Test',
                                              'role_id' => 'TECH' } ],
                               'profils' => [ { 'etablissement_code_uai' => 'Test',
                                                'profil_id' => 'ENS' },
                                              { 'etablissement_code_uai' => 'Invalid',
                                                'profil_id' => 'DIR' } ],
                               'profil_actif' => { 'etablissement_code_uai' => 'Test',
                                                   'profil_id' => 'ENS' },
                               'etablissements' => 'dummy',
                               'applications' => 'dummy',
                               'ressources_numeriques' => 'dummy',
                               'enfants' => 'dummy',
                             } }
          end
        end
      end
    end

    result = subject.new.user_verbose

    expect( result['profil_actif'] ).to_not be_nil
    expect( result['profil_actif']['etablissement_code_uai'] ).to eq 'Test'
    expect( result['profil_actif']['profil_id'] ).to eq 'ENS'

    expect( result['profils'] ).to_not be_nil
    expect( result['profils'][0]['admin'] ).to be true
    expect( result['profils'][1]['admin'] ).to be false

    expect( result['enfants'] ).to_not be_nil
    expect( result['enfants'] ).to eq 'dummy'

    expect( result['classes'] ).to_not be_nil
    expect( result['classes'].count ).to eq 9
    expect( result['classes'].map { |c| c['id'] }.count ).to eq 9
    expect( result['classes'].map { |c| c['libelle'] }.count ).to eq 9
    expect( result['classes'].map { |c| c['type'] }.count ).to eq 9
    expect( result['classes'].map { |c| c['type'] }.select { |c| c == 'classe' }.count ).to eq 3
    expect( result['classes'].map { |c| c['type'] }.select { |c| c == 'groupe' }.count ).to eq 6

    expect( result['marqueur_xiti'] ).to eq ''

    expect( result[:user_detailed]['profil_actif'] ).to be_nil
    expect( result[:user_detailed]['etablissements'] ).to be_nil
    expect( result[:user_detailed]['applications'] ).to be_nil
    expect( result[:user_detailed]['ressources_numeriques'] ).to be_nil
    expect( result[:user_detailed]['profils'] ).to be_nil
    expect( result[:user_detailed]['enfants'] ).to be_nil
    expect( result[:user_detailed]['classes'] ).to be_nil
    expect( result[:user_detailed]['groupes_eleves'] ).to be_nil
    expect( result[:user_detailed]['groupes_libres'] ).to be_nil
    expect( result[:user_detailed]['roles'] ).to be_nil
  end
end
