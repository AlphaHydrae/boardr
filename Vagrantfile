# -*- mode: ruby -*-
# vi: set ft=ruby :

# https://docs.vagrantup.com
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/bionic64'

  config.vm.network 'private_network', ip: '192.168.50.4'

  config.vm.provider 'virtualbox' do |virtual_box|
    virtual_box.cpus = 4
    virtual_box.memory = '2048'
  end

  config.vm.provision 'ansible' do |ansible|
    ansible.compatibility_mode = '2.0'
    ansible.playbook = 'vagrant/playbook.yml'
    ansible.skip_tags = ENV.fetch('ANSIBLE_SKIP_TAGS', '').split(',')
    ansible.tags = ENV.key?('ANSIBLE_TAGS') ? ENV.fetch('ANSIBLE_TAGS', '').split(',') : nil
    ansible.verbose = '-vv'
  end
end