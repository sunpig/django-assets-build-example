#!/bin/bash

# Create the deployment directory
START_DATE=`date +%Y-%m-%dT%H-%M-%S`
BASE_DIR="/var/apps/example_project"
DEPLOY_DIR="$BASE_DIR/releases/$START_DATE"
STATIC_DIR="$DEPLOY_DIR/build/static"
mkdir -p $STATIC_DIR

# Copy the necessary files. 
rsync /vagrant/example_project $DEPLOY_DIR --exclude "__pycache__/" -avz --delete
rsync /vagrant/build/static/prod $STATIC_DIR -avz --delete
rsync /vagrant/requirements.txt $DEPLOY_DIR -avz

# Create a fresh virtualenv
virtualenv "$DEPLOY_DIR/venv" -p python3.5

# Activate virtualenv and install requirements
source "$DEPLOY_DIR/venv/bin/activate"
pip install -r "$DEPLOY_DIR/requirements.txt"

# Symlink to the current installation
ln -sfn "$DEPLOY_DIR" "$BASE_DIR/current"

# Sledgehammer the ownership of files
sudo chown -R www-data:www-data $DEPLOY_DIR
sudo chown -R www-data:www-data "$BASE_DIR/current"

# Deactivate virtualenv
deactivate

# Restart uwsgi app
sudo systemctl restart uwsgi
