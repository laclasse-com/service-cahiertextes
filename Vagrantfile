# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "precise64-v1.2"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.define :webapp do |webapp|
    webapp.vm.hostname = "webapp.local"
    webapp.vm.network :private_network, ip: "192.168.123.3"
    webapp.vm.synced_folder "./", "/home/vagrant/app"
    webapp.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 200, "--name", "vagrant-cahiertxt"]
    end
  end

  #
  # Provisionning
  #
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "vagrant/provision.yml"
    ansible.inventory_file = "vagrant/hosts"
    ansible.sudo = true
    ansible.verbose = true
    ansible.limit = "192.168.123.3"
    # Change your stuff here
    ansible.extra_vars = { ruby_version: "2.0.0-p235",
                           app_start_command: "bundle && bundle exec rackup",
                           mysql_db: "cahiertxt",
                           mysql_user: "root",
                           mysql_pass: "vagrant",
                           mysql_privs: "ALL" }
  end
end
