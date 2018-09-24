# frozen_string_literal: true

module LaClasse
    module Helpers
        module Auth
            module_function

            def session
                { 'user' => 'VZZ69999' }
            end

            def logged?
                true            # Yeah yeah you are logged *wink*
            end

            def login!
                nop
            end
        end
    end
end

module LaClasse
    module Helpers
        module User
            module_function

            def user
                { 'id' => "VZZ69999"}
            end

            def user_needs_to_be( _profile_types, _uid = nil )
                true
            end
        end
    end
end

MOCK_UAI = '0699999Z'
