# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "precise64-v1.2"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.define :webapp do |webapp|
    webapp.vm.hostname = "webapp.local"
    webapp.vm.network :private_network, ip: "192.168.123.2"
    webapp.vm.synced_folder "./", "/home/vagrant/app"
    webapp.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 200, "--name", "vagrant-cahiertextes", "--natdnshostresolver1", "on"]
    end
  end

  # 
  # Provisionning
  #
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "vagrant/provision.yml"
    ansible.inventory_path = "vagrant/hosts"
    ansible.sudo = true
    #
    # Use anible.tags if you want to restrict what `vagrant provision`
    # Here is a list of possible tags
    # ansible.tags = "apt backup bash config git mysql ntp ruby ruby:config ruby:install sys tmux tmux:config tmux:install"
    #
    # Use ansible.verbose to see detailled output for ansible runs
    # ansible.verbose = 'vvv'
    #
    # Customize your stuff here
    ansible.extra_vars = { 
      ruby_versions: [ "2.1.1" ],
      app_start_command: "bundle && bundle exec rackup",
      mysql: { 
        root_password: "toortoor",
        users:
        [ name:     "vagrant",
          password: "vagrant",
          privs:    "cahiertextes.*:ALL" ],
      },
    }
  end
end
