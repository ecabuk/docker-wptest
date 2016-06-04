#!/bin/bash

##########################################################################
# Create base directories if not exist
##########################################################################
if [ ! -d ${WP_CORE_DIR_BASE} ]; then
    mkdir -p ${WP_CORE_DIR_BASE}
fi

if [ ! -d ${WP_TEST_DIR_BASE} ]; then
    mkdir -p ${WP_TEST_DIR_BASE}
fi


##########################################################################
# Cleanes svn directories
##########################################################################
clean_svn_dir() {
	# Revert normal local svn changes
	svn revert --quiet -R $1

	# Remove any other change and supports removing files/folders with spaces, etc.
	svn status --no-ignore $1 | grep -E '(^\?)|(^\I)' | sed -e 's/^. *//' | sed -e 's/\(.*\)/"\1"/' | xargs rm -rf

	# Get the latest files from svn
	svn update --quiet --force $1
}


##########################################################################
# Install wordpress core
##########################################################################
install_wp() {
	if [ -d ${WP_CORE_DIR} ]; then
		echo "Previous core files found, cleaning..."
	    clean_svn_dir "${WP_CORE_DIR}"
	else
		echo "Installing core files..."
	    svn co --quiet http://core.svn.wordpress.org/${WP_SVN_TAG} "${WP_CORE_DIR}"
	fi

    # To prevent external db call errors we need to add that
	echo "<?php
            if ( ! defined( 'WP_USE_EXT_MYSQL' ) ) {
                define( 'WP_USE_EXT_MYSQL', false );
            }" > "${WP_CORE_DIR}/wp-content/db.php"
}


##########################################################################
# Install wordpress test suite
##########################################################################
install_test_suite() {
    echo "Installing test helpers..."

	# Create test suite folder if it doesn't yet exist
	if [ ! -d ${WP_TEST_DIR} ]; then
		mkdir -p "${WP_TEST_DIR}"
	fi

	# Setup includes folder
	if [ -d "${WP_TEST_DIR}/includes" ]; then
		echo "Previous test files found, cleaning..."
	    clean_svn_dir "${WP_TEST_DIR}/includes"
    else
    	echo "Installing test files..."
        svn co --quiet https://develop.svn.wordpress.org/${WP_SVN_TAG}/tests/phpunit/includes/ "${WP_TEST_DIR}/includes"
	fi

	# Download sample config files if it doesn't exist yet
	if [ ! -f "${WP_TEST_DIR}/wp-tests-config-sample.php" ]; then
        curl -s  https://develop.svn.wordpress.org/${WP_SVN_TAG}/wp-tests-config-sample.php > "${WP_TEST_DIR}/wp-tests-config-sample.php"
	fi

    # Clean test config file
    WP_TESTS_CONFIG_FILE="${WP_TEST_DIR}/wp-tests-config.php"
	cp -f "${WP_TEST_DIR}/wp-tests-config-sample.php" ${WP_TESTS_CONFIG_FILE}

    # Set test configs
	sed -i "s:dirname( __FILE__ ) . '/src/':'${WP_CORE_DIR}/':" ${WP_TESTS_CONFIG_FILE}
	sed -i "s/youremptytestdbnamehere/${DB_NAME}/" ${WP_TESTS_CONFIG_FILE}
    sed -i "s/yourusernamehere/$DB_USER/" ${WP_TESTS_CONFIG_FILE}
    sed -i "s/yourpasswordhere/$DB_PASS/" ${WP_TESTS_CONFIG_FILE}
    sed -i "s|localhost|${DB_HOST}|" ${WP_TESTS_CONFIG_FILE}
    sed -i "s/example.org/${WP_TESTS_DOMAIN}\:${WP_TESTS_PORT}\/${WP_VERSION}/" ${WP_TESTS_CONFIG_FILE}

    # Clean config file
    WP_CONFIG_FILE="${WP_CORE_DIR}/wp-config.php"
    cp -f "${WP_CORE_DIR}/wp-config-sample.php" ${WP_CONFIG_FILE}
    sed -i "s/database_name_here/${DB_NAME}/" ${WP_CONFIG_FILE}
    sed -i "s/username_here/$DB_USER/" ${WP_CONFIG_FILE}
    sed -i "s/password_here/$DB_PASS/" ${WP_CONFIG_FILE}
    sed -i "s/table_prefix  = 'wp_'/table_prefix  = 'wptests_'/" ${WP_CONFIG_FILE}
    sed -i "s|localhost|${DB_HOST}|" ${WP_CONFIG_FILE}
}


##########################################################################
# Install database
##########################################################################
prepare_db() {
    echo "Preparing database..."

	php-7.0 /prepare_db.php "$DB_HOST" "$DB_USER" "$DB_PASS" "$DB_NAME"
}



##########################################################################
# Merge content folder
##########################################################################
merge_wp_content() {
	echo "Merging the /wp-content folder..."
	rsync -a /wp-content $WP_CORE_DIR
	chown -R wwwrun.www-data $WP_CORE_DIR/wp-content
}

##########################################################################
# Link content folder
##########################################################################
link_wp_content() {
	echo "Linking the /wp-content folder..."
	for CONTENT_BASE_DIR in /wp-content/*/; do
		for CONTENT_DIR in $CONTENT_BASE_DIR*/; do
			ln -s $CONTENT_DIR $WP_CORE_DIR/wp-content/$(basename $CONTENT_BASE_DIR)/$(basename $CONTENT_DIR)
		done
	done
}


##########################################################################
# Start setup
##########################################################################
echo "Setting up WordPress ${WP_VERSION} & PHP ${PHP_VERSION} test suite..."
install_wp
install_test_suite
prepare_db
if [[ MERGE_WP_CONTENT = true ]]; then
	merge_wp_content
else
	link_wp_content
fi

echo 'Done!'