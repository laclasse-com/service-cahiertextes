#!/bin/bash

install() {
    MYSQL_PASSWORD=tartempion
    echo 'bootstrapping VM'

    echo 'installing missing packages'
    sudo apt-get update

    sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD'
    sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD'

    sudo apt-get -y install git make mysql-server-5.5 libmysqlclient-dev sqlite3 libsqlite3-dev

    # up-to-date nodejs, https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#ubuntu-mint
    sudo apt-get update
    sudo apt-get install -y python-software-properties python g++ make
    sudo add-apt-repository -y ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install nodejs

    echo 'installing bower'
    sudo npm install -g bower
    
    echo 'installing rbenv'
    git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    source ~/.bash_profile

    echo 'installing ruby'
    rbenv install 2.0.0-p247
    rbenv global 2.0.0-p247
    
    echo 'installing bundler'
    gem install bundler

    echo 'you have to setup DB for cahier-de-textes'
    echo 'you have to run bundle install'

    #
    # Symlink app
    #
    ln -s /vagrant cahier-de-textes
    cd cahier-de-textes/
} 

# Exit if already bootstrapped.
test -f /etc/bootstrapped && exit

export -f install
su vagrant -c 'install'

# Mark as bootstrapped 
date > /etc/bootstrapped
