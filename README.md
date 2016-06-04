# Usage

Sample docker-compose.yml file.

```yaml
version: '2'
services:
  test:
    image: ecabuk/wptest
    restart: 'no'
    depends_on:
      - db
      - selenium
    links:
      - db
      - selenium
    volumes:
      - ".:/wp-content/plugins/MY_PLUGIN_DIR"
      - "./tmp/itemify_tests:/var/www"
    environment:
      TEST_USER: wwwrun
      TEST_UID: $TEST_UID
      DB_HOST: db:3306
      DB_USER: root
      DB_PASS: wordpress
  db:
    image: mariadb:10
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: wordpress
  selenium:
    image: selenium/standalone-firefox-debug
    restart: always
```

Sample .travis.yml file.
```yaml
language: php
php:
  - '5.6'
sudo: required
dist: trusty

services:
  - docker

git:
  depth: 1

env:
  global:
    - DOCKER_COMPOSE_VERSION: 1.7.1
  matrix:
    - WP_VERSION="latest" PHP_VERSION="5.5"
    - WP_VERSION="latest" PHP_VERSION="7.0"
    - WP_VERSION="nightly" PHP_VERSION="7.0"

cache:
  directories:
    - tmp/itemify_tests

install:
  # update docker
  - sudo apt-get update
  - sudo apt-get -o Dpkg::Options::="--force-confnew" install -y docker-engine

  # update docker-compose
  - sudo pip install --upgrade docker-compose

before_script:
  - export TEST_UID=$(id -u)
  - export TEST_USER=wwwrun
  - docker-compose up -d test
  - sleep 10
  - docker-compose exec test prepare $WP_VERSION $PHP_VERSION

script:
  - docker-compose exec test su - $TEST_USER -c "cd \$WP_CORE_DIR/wp-content/plugins/MY_PLUGIN_DIR;phpunit"

after_failure:
  - docker-compose logs test
```