#!/bin/bash

##########################################################################
# Crate the test user
##########################################################################
: ${TEST_USER:=wwwrun}

/bin/egrep  -i "^$TEST_USER:" /etc/passwd
if [ $? -eq 0 ]; then
	echo "Test user '$TEST_USER' already exist..."
else
	useradd --home /var/www --gid www-data -M -N --uid $TEST_UID -s /bin/bash $TEST_USER
	echo "export APACHE_RUN_USER=$TEST_USER" >> /etc/apache2/envvars
	chown -R $TEST_USER /var/lib/apache2
	chown $TEST_USER /var/www
	echo "Test user '$TEST_USER' added..."
fi


apache2ctl -D FOREGROUND