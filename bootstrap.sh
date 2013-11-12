#!/bin/bash

install() {
    echo 'bootstrapping VM'

    echo 'installing missing packages'
    sudo apt-get update

    sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password tartempion'
    sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password tartempion'

    sudo apt-get -y install git make mysql-server-5.5 libmysqlclient-dev sqlite3 libsqlite3-dev pwgen python-software-properties python g++ make

    # up-to-date nodejs, https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#ubuntu-mint
    sudo add-apt-repository -y ppa:chris-lea/node.js
    sudo apt-get update
    sudo apt-get install -y nodejs

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
    rbenv rehash

    echo 'setup DB for cahier-de-textes'
    TMPFILE=$(mktemp)
    PASSWORD=$(pwgen 42 1)
    cat <<EOF > $TMPFILE
CREATE USER 'cahierdetextes'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT USAGE ON * . * TO 'cahierdetextes'@'localhost' IDENTIFIED BY '$PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;
CREATE DATABASE IF NOT EXISTS cahierdetextes ;
GRANT ALL PRIVILEGES ON \`cahierdetextes\` . * TO 'cahierdetextes'@'localhost';
EOF
    cat $TMPFILE | mysql --user=root --password=tartempion
    rm $TMPFILE

    cat <<EOF | bundle exec rake db:configure
cahierdetextes
localhost
cahierdetextes
$PASSWORD
EOF

    #
    # Symlink app
    #
    ln -s /vagrant cahier-de-textes
    cd cahier-de-textes/

    echo 'running bundle install'
    bundle install
} 

# Exit if already bootstrapped.
test -f /etc/bootstrapped && exit

export -f install
su vagrant -c 'install'

# Mark as bootstrapped 
date > /etc/bootstrapped
