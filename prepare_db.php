<?php

$stderr = fopen( 'php://stderr', 'w' );
@list( $host, $port ) = explode( ':', $argv[1], 2 );
$maxTries = 10;
do {
	$mysql = new mysqli( $host, $argv[2], $argv[3], '', (int) $port );
	if ( $mysql->connect_error ) {
		fwrite( $stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n" );
		-- $maxTries;
		if ( $maxTries <= 0 ) {
			exit( 1 );
		}
		sleep( 3 );
	}
} while ( $mysql->connect_error );
if (
	! $mysql->query( 'DROP DATABASE IF EXISTS `' . $mysql->real_escape_string( $argv[4] ) . '`' ) ||
	! $mysql->query( 'CREATE DATABASE `' . $mysql->real_escape_string( $argv[4] ) . '`' )
) {
	fwrite( $stderr, "\n" . 'MySQL Query Error: ' . $mysql->error . "\n" );
	$mysql->close();
	exit( 1 );
}
$mysql->close();