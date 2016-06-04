FROM splitbrain/phpfarm:jessie
MAINTAINER Evrim Cabuk <ecabuk@ecabuk.net>

RUN apt-get update && \
apt-get -y install subversion && \
rm -rf /var/lib/apt/lists/*

ADD https://phar.phpunit.de/phpunit-old.phar /usr/bin/phpunit-old
ADD https://phar.phpunit.de/phpunit.phar /usr/bin/phpunit-new
RUN chmod 755 /usr/bin/phpunit-*

COPY entrypoint.sh /entrypoint.sh
COPY prepare.sh /usr/bin/prepare
COPY prepare_by_user.sh /usr/bin/prepare_by_user
COPY prepare_db.php /prepare_db.php
RUN chmod +x /entrypoint.sh /usr/bin/prepare /usr/bin/prepare_by_user

ENTRYPOINT ["/entrypoint.sh"]