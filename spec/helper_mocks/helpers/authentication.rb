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
