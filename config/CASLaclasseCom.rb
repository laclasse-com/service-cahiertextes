# -*- coding: utf-8 -*-

# CAS Configuration.
module CASLaclasseCom
  OPTIONS = { host: 'www.dev.laclasse.com',
              ssl: true,
              port: 443,
              disable_ssl_verification: true,
              login_url: '/sso/login',
              service_validate_url: '/sso/serviceValidate',
              logout_url: '/sso/logout' }
end
