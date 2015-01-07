# -*- encoding: utf-8 -*-

require_relative '../lib/HashedUser'

module CahierDeTextesApp
  module Helpers
    module User
      def user
        HashedUser.new env['rack.session'][:current_user]
      end
    end
  end
end
