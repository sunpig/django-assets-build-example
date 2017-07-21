# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial64"

  # Base box gives 384MB memory - give it a bit more than that.
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create forwarded port mappings that allow access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 8000 on the guest machine.
  config.vm.network "forwarded_port", guest: 8000, host: 8000  # for access to django development server
  config.vm.network "forwarded_port", guest: 80, host: 8080  # for access to nginx + uwsgi (mimics production)

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "dev_vm::main"

    # Custom attributes
    chef.json = {
      "project_name" => "example_project"  # Don't put spaces or dashes in the pro
    }
  end

end
