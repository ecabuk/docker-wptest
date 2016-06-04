#!/bin/bash

WP_VERSION=${1}
PHP_VERSION=${2}

##########################################################################
# Determine WordPress version
##########################################################################
if [[ $WP_VERSION =~ [0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
	WP_SVN_TAG="tags/${WP_VERSION}"
elif [[ ${WP_VERSION} == 'nightly' || ${WP_VERSION} == 'trunk' ]]; then
    WP_VERSION="trunk"
	WP_SVN_TAG="trunk"
else
	# http serves a single offer, whereas https serves multiple. we only want one
	curl -s http://api.wordpress.org/core/version-check/1.7/ > /tmp/wp-latest.json
	grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
	LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
	if [[ -z "$LATEST_VERSION" ]]; then
		echo >&2 "error: Latest WordPress version could not be found."
		exit 1
	fi
	WP_SVN_TAG="tags/$LATEST_VERSION"
	WP_VERSION=${LATEST_VERSION}
fi


##########################################################################
# Determine Port by PHP version
##########################################################################
if [[ $PHP_VERSION = '5.4' ]]; then 
	WP_TESTS_PORT='8054'
	PHPUNIT_SUFFIX='old'
elif [[ $PHP_VERSION = '5.5' ]]; then 
	WP_TESTS_PORT='8055'
	PHPUNIT_SUFFIX='old'
elif [[ $PHP_VERSION = '5.6' ]]; then 
	WP_TESTS_PORT='8056'
	PHPUNIT_SUFFIX='new'
elif [[ $PHP_VERSION = '7.0' ]]; then 
	WP_TESTS_PORT='8070'
	PHPUNIT_SUFFIX='new'
else
	echo >&2 "error: Unsupported php version."
	exit 1
fi

# Create symbolic link for php & phpunit
ln -sf /phpfarm/inst/bin/php-${PHP_VERSION} /usr/bin/php
ln -sf /usr/bin/phpunit-${PHPUNIT_SUFFIX} /usr/bin/phpunit

##########################################################################
# Check content folder
##########################################################################
if [ ! -d /wp-content ]; then
	echo >&2 'error: /wp-content folder missing. Perhaps you forget to mount it?'
	exit 1
fi

##########################################################################
# Set variables
##########################################################################
: ${DB_HOST:=mysql}
: ${DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}
if [ "$DB_USER" = 'root' ]; then : ${DB_PASS:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}; fi
: ${DB_PASS:=$MYSQL_ENV_MYSQL_PASSWORD}
: ${DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-wp_test}}
: ${WP_BASE_DIR:=/var/www}
: ${WP_TESTS_DOMAIN:=$(hostname -I | cut -f1 -d' ' | xargs)}
WP_CORE_DIR_BASE=${WP_BASE_DIR}
WP_TEST_DIR_BASE=${WP_BASE_DIR}/tests
WP_CORE_DIR=${WP_CORE_DIR_BASE}/${WP_VERSION}
WP_TEST_DIR=${WP_TEST_DIR_BASE}/${WP_VERSION}

# Check db credentials
if [ -z "$DB_HOST" ] || [ -z "$DB_PASS" ]; then
	echo >&2 'error: Required database environment variables is missing.'
	exit 1
fi

# Set variables
cat << EOF > /var/www/activate
export PHP_VERSION=$PHP_VERSION
export WP_VERSION=$WP_VERSION
export WP_SVN_TAG=$WP_SVN_TAG
export WP_CORE_DIR_BASE=$WP_CORE_DIR_BASE
export WP_TEST_DIR_BASE=$WP_TEST_DIR_BASE
export WP_CORE_DIR=$WP_CORE_DIR
export WP_TEST_DIR=$WP_TEST_DIR
export WP_TESTS_DOMAIN=$WP_TESTS_DOMAIN
export WP_TESTS_PORT=$WP_TESTS_PORT
export DB_HOST=$DB_HOST
export DB_USER=$DB_USER
export DB_NAME=$DB_NAME
export DB_PASS=$DB_PASS
export MERGE_WP_CONTENT=${MERGE_WP_CONTENT:-false}
export WP_TEST_URL="http://${WP_TESTS_DOMAIN}:${WP_TESTS_PORT}/${WP_VERSION}"
EOF

# Create profile
cat << EOF > /var/www/.profile
source /var/www/activate
export PATH=$PATH
EOF

/bin/egrep  -i "^wwwrun:" /etc/passwd
if [ $? -eq 0 ]; then
	su - wwwrun -c prepare_by_user
else
	prepare_by_user
fi
