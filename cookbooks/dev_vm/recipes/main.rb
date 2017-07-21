# =====================================================
# Single recipe to set up a dev VM. This could be 
# split into multiple files, but ¯\_(ツ)_/¯
#
# Expected recipe attributes:
#  node.normal["project_name"]
#

require 'securerandom'

project_name = node.normal["project_name"]


# In Ubuntu's xenial xerus box, the default user created is "ubuntu"

execute "update repositories" do
  command "apt-get update -y"
  action :run
end

apt_packages = [
  "build-essential", # for the "make" command, and for installing nvm
  "python3", # install the default python3 for bootstrapping. In the actual virtualenv for app dev purposes, lock down the python version that will be used.
  "python3-pip", # install the default pip3 for use with python3.
	"virtualenv", # install virtualenv for setting up virtualenvs for isolated app dev
  "postgresql-9.5", # Even though later postgres versions are available, 9.5 is fine. 
  "libpq-dev", # for building client libraries, including the psycopg2 pip module for connecting to PG databases
  "python3.5-dev", # contains the Python.h header files needed for building psycopg2 for python 3.5
  "libssl-dev", # for installing nvm
  "nginx" # for emulating production environment
]
apt_packages.each do |pkg|
  apt_package pkg do
    action :upgrade # install or upgrade
  end
end

# Create virtualenvs directory
directory '/home/ubuntu/.envs' do
  owner 'ubuntu'
  group 'ubuntu'
  mode '0755'
  action :create
end

execute "make new virtualenv for project with python3.5" do
  user "ubuntu"
  group "ubuntu"
  command "cd /home/ubuntu/.envs;virtualenv #{project_name} -p python3.5"
  action :run
  not_if { ::Dir.exist?("/home/ubuntu/.envs/#{project_name}") }
end

# Muck about with profile stuff for the default user (ubuntu)
template "/home/ubuntu/.bashrc_extra" do
  source "bashrc_extra.erb"
  owner "ubuntu"
  group "ubuntu"
  mode 0644
  action :create
  variables({
    :project_name => project_name
  })
end

execute "source .bashrc_extra" do
  command "echo \"source /home/ubuntu/.bashrc_extra\" >> /home/ubuntu/.bashrc"
  not_if "grep bashrc_extra /home/ubuntu/.bashrc"
end

# nvm (node version manager) is just a bash script helper for installing node.
# Get it from https://github.com/creationix/nvm/blob/master/nvm.sh
# The manual way to install nvm itself is just to put the shell script
# in a folder, and set some env vars.
directory '/home/ubuntu/.nvm' do
  owner 'ubuntu'
  group 'ubuntu'
  mode '0755'
  action :create
end

cookbook_file "/home/ubuntu/.nvm/nvm.sh" do
  owner "ubuntu"
  group "ubuntu"
  source "nvm.sh"
  mode 0644
  action :create
end

# Nodejs is not used in production, only for development and deployment
# (compile, compress, & concat client-side assets)
# Install a stable LTS version using nvm
# Note that this version of node will only be available to the installing user ('ubuntu')
node_version = 'v6.11.0' # LTS
bash "install node" do
  user 'ubuntu'
  environment 'NVM_DIR' => '/home/ubuntu/.nvm';
  code "source /home/ubuntu/.nvm/nvm.sh; nvm install #{node_version}"
  action :run
end
# Install node dev dependencies
bash "install node dev dependencies" do
  user 'ubuntu'
  cwd '/vagrant';
  # npm needs some environment variables set explicitly to operate properly as the selected user
  # http://stackoverflow.com/questions/23772737/npm-install-with-chef-lead-to-eacces-issue-in-my-vagrant-user
  environment ({
    'HOME' => "/home/ubuntu",
    'PATH' => "/home/ubuntu/.nvm/versions/node/#{node_version}/bin:#{ENV['PATH']}",
  })
  code "npm install"
  action :run
end

# Drop and recreate the dev database, and drop-and-recreate a user
# See also https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04 
# Note that the dropping and recreating means you'll have to re-run migrations
# and re-import any database backups.

project_database_name = "#{project_name}_db"
project_database_user = "#{project_name}_user"
project_database_password = SecureRandom.hex

execute "drop user" do
  command "psql --command \"drop user if exists #{project_database_user}\""
  user "postgres"
  action :run
end

execute "create user" do
  command "psql --command \"create user #{project_database_user} with createdb password '#{project_database_password}'\""
  user "postgres"
  action :run
end

execute "drop database" do
  command "psql --command \"drop database if exists #{project_database_name}\""
  user "postgres"
  action :run
end

execute "create database" do
  command "createdb --owner=#{project_database_user} #{project_database_name}"
  user "postgres"
  action :run
end


# Note that by default, any new user can create tables in the public schema of a postgres database.
# So no need for granting additional permissions right now.


# Build a file with environment variables for 12-factor app configuration
directory "/var/apps/#{project_name}" do
  owner 'root'
  group 'adm'
  mode '0775'
  recursive true
  action :create
end

project_secret_key = SecureRandom.hex

template "/var/apps/#{project_name}/#{project_name}.env" do
  source "project.env.erb"
  mode 0644
  owner "root"
  group "adm"
  action :create
  variables({
    :project_secret_key => project_secret_key,
    :project_debug => "True",
    :project_database_engine => "django.db.backends.postgresql",
    :project_database_name => project_database_name,
    :project_database_user => project_database_user,
    :project_database_password => project_database_password,
    :project_database_host => "127.0.0.1",
    :project_database_port => "5432",
  })
end

################################
# Create a staging environment in the VM to mimic production in certain key aspects:
# * uwsgi in emperor mode
# * uwsgi will run the app as the www-data user
# * app will be stored in /var/apps/#{project_name}. Each deploy will go
#   into a timestamped subdirectory; the current version will be symlinked to a `current` directory.
# * uwsgi log: /var/log/uwsgi/#{project_name}.log
# * nginx access log: /var/log/nginx/#{project_name}.access.log
# * nginx error log: /var/log/nginx/#{project_name}.error.log
# * uwsgi socket: /var/run/uwsgi/#{project_name}.sock (owner: www-data:www-data)
#
# The idea being:
# * In development, work with the django development server.
# * Access the development server from the host machine as localhost:8000
# * From within the VM, deploy to the VM-based staging environment
#   * When you ssh into the VM, you're using the 'ubuntu' user. All deployment tools (e.g. node) can assume this user.
#   * The app in the staging environment will be run under the www-data account.
# * From the host machine, access the app via nginx at localhost:8080
#
################################

# The www-data will be running the app, but the ubuntu user
# is doing all the deployment. Add the ubuntu (VM) user to
# the www-data group, so we can enable group permissions and have
# ubuntu be able to do everything.
group 'www-data' do
  action :modify
  members 'ubuntu'
  append true
end

# Install uwsgi. Running pip3 install as root will put the binary at /usr/local/bin/uwsgi
execute "install uwsgi" do
  user "root"
  command "pip3 install uwsgi"
  action :run
end

# Create a config directory for uwsgi
directory '/etc/uwsgi/sites' do
  mode '0755'
  recursive true
  action :create
end

# Create an ini file for running the app under uwsgi
template "/etc/uwsgi/sites/#{project_name}_uwsgi.ini" do
  source "project_uwsgi.ini.erb"
  mode 0644
  action :create
  variables({
    :project_name => project_name
  })
end

# Ensure a log directory exists
directory '/var/log/uwsgi' do
  mode '0755'
  recursive true
  action :create
end

# Ensure a socket directory exists
directory '/var/run/uwsgi' do
  mode '0755'
  recursive true
  action :create
end

# Set up uwsgi to run as a service:
# 1: Add service definition
cookbook_file "/etc/systemd/system/uwsgi.service" do
  source "uwsgi.service"
  mode 0644
  action :create
end
# 2: Start the uwsgi service, and enable it to run at startup
execute "start uwsgi service" do
  command "systemctl start uwsgi"
  action :run
end
execute "enable uwsgi service" do
  command "systemctl enable uwsgi"
  action :run
end


# Set up nginx to talk to uwsgi 
# 1: Remove the default site
file '/etc/nginx/sites-enabled/default' do
  action :delete
end
# 2: Define the new site
template "/etc/nginx/sites-available/#{project_name}_nginx_site" do
  source "project_nginx_site.erb"
  mode 0644
  action :create
  variables({
    :project_name => project_name
  })
end
# 3: Enable the new site
link '/etc/nginx/sites-enabled/#{project_name}_nginx_site' do
  to '/etc/nginx/sites-available/#{project_name}_nginx_site'
end
# 4: Restart nginx to reload config
execute "restart nginx service" do
  command "systemctl restart nginx"
  action :run
end
