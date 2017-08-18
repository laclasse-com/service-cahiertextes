# coding: utf-8
module LaClasse
  module Helpers
    module Auth
      def session
        return env[:session] unless env[:session].nil?
        session = nil
        unless cookies[:LACLASSE_AUTH].nil?
          RestClient::Request.execute(
            method: :get,
            url: "#{ANNUAIRE[:url]}/sessions/#{cookies[:LACLASSE_AUTH]}") do |response, request, result|
            if result.is_a?(Net::HTTPSuccess)
              session = JSON.parse(response)
              # put the current user in the AUTH_USER for the HTTP request logger
              env['AUTH_USER'] = session['user']
            end
          end
        end
        env[:session] = session unless session.nil?

        session
      end

      def log_exception( exception )
        puts "\"#{env['REQUEST_METHOD']} #{env['REQUEST_URI']}\". Exception catched.
 Message: '#{exception}'. Stack: #{exception.backtrace}"
      end

      def logged?
        !session.nil?
      end

      def login!( route )
        protocol = CASAUTH::CONFIG[:ssl] ? 'https' : 'http'
        service = ''
        if route.empty?
          service = "#{protocol}://#{env['HTTP_HOST']}#{APP_PATH}"
        else
          route += "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
          service = "#{protocol}://#{env['HTTP_HOST']}#{route}"
        end
        redirect "/sso/login?ticket=false&service=" + URI.escape(service)
      end
    end
  end
end
