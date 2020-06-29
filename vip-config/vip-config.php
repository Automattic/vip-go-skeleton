<?php
/**
 * Hi there, VIP dev!
 *
 * vip-config.php is where you put things you'd usually put in wp-config.php. Don't worry about database settings
 * and such, we've taken care of that for you. This is just for if you need to define an API key or something
 * of that nature.
 *
 * WARNING: This file is loaded very early (immediately after `wp-config.php`), which means that most WordPress APIs,
 *   classes, and functions are not available. The code below should be limited to pure PHP.
 *
 * @see https://vip.wordpress.com/documentation/vip-go/understanding-your-vip-go-codebase/
 *
 * Happy Coding!
 *
 * - The WordPress.com VIP Team
 **/

// Set a high default limit to avoid too many revisions from polluting the database.
// Posts with extremely high revisions can result in fatal errors or have performance issues.
// Feel free to adjust this depending on your use cases.
if ( ! defined( 'WP_POST_REVISIONS' ) ) {
	define( 'WP_POST_REVISIONS', 500 );
}

// The VIP_JETPACK_IS_PRIVATE constant is enabled by default in non-production environments.
// It disables programmatic access to content via the WordPress.com REST API and Jetpack Search;
// subscriptions via the WordPress.com Reader; and syndication via the WordPress.com Firehose.
// More information about these features is available in our documentation:
// https://wpvip.com/documentation/vip-go/restricting-access-to-a-site-hosted-on-vip-go/#controlling-content-distribution-via-jetpack
if ( ! defined( 'VIP_JETPACK_IS_PRIVATE' ) && 'production' !== VIP_GO_APP_ENVIRONMENT ) {
    define( 'VIP_JETPACK_IS_PRIVATE', true );
}
