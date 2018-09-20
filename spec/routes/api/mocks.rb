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
