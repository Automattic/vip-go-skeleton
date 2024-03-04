<?php
/**
 * Modify Jetpack behavior in this file according to your needs.
 */

/**
* Disable the Jetpack Enhanced distribution feature.
*/
add_filter( 'jetpack_get_available_modules', function( $modules ) {
	unset( $modules[ 'enhanced-distribution' ] );
	return $modules;
}, 1000 );
