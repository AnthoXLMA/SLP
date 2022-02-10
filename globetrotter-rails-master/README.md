# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Deployment instructions for dev

1. Install docker/docker-compose

Follow instructions at https://docs.docker.com/engine/install / https://docs.docker.com/compose/install/

2. Install ruby

A simple way is to use rbenv: https://github.com/rbenv/rbenv-installer
The following packages are required:
```
apt-get install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev
```

3. Install helm

Follow the instructions at https://helm.sh/docs/intro/install/.
A simple way is to run:
```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
```


4. Get the file `config/master.key`

This file contains the encryption key of the credentials saved in the repo.


5. Build/Deploy 

  1. locally the production images using docker-compose

```
rake docker-compose:build
rake docker-compose:up
```

The env should be available at http://localhost:8000

  2. Build locally / deploy on Azure aks

```
rake aks:deploy
```


6. Install tooling for development

Install postgresql-client-12

```
 wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
 echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
 sudo apt update
 sudo apt install postgresql-client-12
 ```

7. Get required local packages for developement

```
# required lib for postgresql
sudo apt install libpq-dev

# ruby dependencies
gem install bundler
bundle install

# required node/yarn
see Dockerfile

```

8. Deploy the development version

```
# rails application
bin/rails server

# optional: live reload of js asset
bin/webpack-dev-server

# optional live reload of the browser
bin/guard
```
