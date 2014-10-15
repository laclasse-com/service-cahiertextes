# -*- coding: utf-8 -*-

require 'spec_helper'

feature CahierDeTextesAPI::Web do
  include Rack::Test::Methods

  # before :each do
  #   db_cleaner = TableCleaner.new DB, []
  #   db_cleaner.clean
  # end

  it 'loads the web-app' do
    visit "#{APP_PATH}/#/enseignant/emploi_du_temps"

    show_me_the_cookies

    # expect( current_url ).to match %r{^http[s]?://#{CASAUTH::CONFIG[:host]}#{CASAUTH::CONFIG[:login_url]}.*}
  end

end
