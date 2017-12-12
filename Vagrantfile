# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.ssh.username = "admin"
  config.ssh.private_key_path = "~/.ssh/id_rsa"
  config.ssh.port = "50022"

  config.vm.box = "centos_7_x86_64_base"
  config.vm.define "wp" do |wp|
  wp.vm.hostname = "wp"
  wp.vm.network "forwarded_port", guest:80, host: 50080
  wp.vm.network "forwarded_port", guest:22, host: 50022

  wp.vm.provider "virtualbox" do |vb|
  vb.name = "wp"
  vb.linked_clone = true
  vb.gui = true
  end

end

  config.vm.provision :ansible do |ansible|
    ansible.playbook = "./site.yml"
    ansible.inventory_path = "./hosts"
	end
  end

