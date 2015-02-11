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
          def rack_session_current_user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => '0699999Z',
                                              'role_id' => 'TECH'
                                            } ]
                             }
            }
          end
        end
      end
    end
    uai = '0699999Z'

    expect( subject.new.user_is_admin_in_etablissement?( uai ) ).to be true
  end

  it 'Checks that the user is admin in a given etablissement when he have a ADM_* role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def rack_session_current_user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => '0699999Z',
                                              'role_id' => 'ADM_ETB'
                                            } ]
                             }
            }
          end
        end
      end
    end
    uai = '0699999Z'

    expect( subject.new.user_is_admin_in_etablissement?( uai ) ).to be true
  end

  it 'Checks that the user is NOT admin in a given etablissement when he have another role' do
    module CahierDeTextesApp
      module Helpers
        module User
          def rack_session_current_user
            { user_detailed: { 'roles' => [ { 'etablissement_code_uai' => '0699999Z',
                                              'role_id' => 'Pirate'
                                            } ]
                             }
            }
          end
        end
      end
    end
    uai = '0699999Z'

    expect( subject.new.user_is_admin_in_etablissement?( uai ) ).to be false
  end
end
