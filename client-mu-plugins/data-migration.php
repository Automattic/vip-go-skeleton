<?php

/**
 * Run some cleanup after a migration.
 *
 * Will run after the sync is done, and before we loop through sites in a multisite.
 *
 * @uses vip_after_data_migration
 */
function sample_vip_after_data_migration() {

    // Don't run in production.
    if ( 'production' === VIP_GO_ENV ) {
        return;
    }

    // If running multisite, make any network-level modifications here.
    // For example, resetting network options.

}
add_action( 'vip_after_data_migration', 'sample_vip_after_data_migration' );

/**
 * Run some per-site custom cleanup after a migration.
 *
 * Gets triggered for each site within a multisite environment.
 *
 * @uses vip_go_migration_cleanup
 *
 * @param bool $dry_run Whether we're doing a dry run or not.
 */
function sample_vip_go_migration_cleanup( $dry_run ) {

    // Don't run in production.
    if ( 'production' === VIP_GO_ENV ) {
        return;
    }

    // Options to change after sync. Each key is the option name, and each value
    // is the value. NULL will be considered an instruction to DELETE that option.
    $option_values = [
        'blog_public' => -1, // Set privacy option to Private.
    ];

    foreach ( $option_values as $name => $value ) {

        if ( is_null( $value ) ) {

            if ( ! $dry_run ) {
                delete_option( $name );
            }

        } else {

            if ( ! $dry_run ) {
                update_option( $name, $value );
            }

        }

    }

}
add_action( 'vip_go_migration_cleanup', 'sample_vip_go_migration_cleanup' );
