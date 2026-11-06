# VIP platform reference

Optional recipes for specific platform questions. Read only the relevant section when needed; these are not additional tasks or a validation checklist. Existing project configuration determines tooling and workflow.

## Plugin loading and early bootstrap

`wpcom_vip_load_plugin()` bypasses activation/deactivation hooks. If a new plugin requires activation-time setup, account for that before enabling it in code; do not assume deploying its files initializes it. On multisite, loading is network-wide unless gated by site.

`vip-config/client-sunrise.php` runs during multisite bootstrap, before plugins and themes. Keep early code narrowly scoped and avoid database or persistent-data access. Domain redirects in `vip-config.php` must exclude WP-CLI and `/cache-healthcheck?` requests; the [redirect example](https://docs.wpvip.com/redirects/domain-redirects-in-vip-config-php/) covers these guards.

Guard reads of `VIP_GO_APP_ENVIRONMENT` with `defined()` for non-VIP tests/local setups. Do not define that platform constant in application code.

[Environment variable](https://docs.wpvip.com/infrastructure/environments/manage-environment-variables/) names cannot start with `WPCOM_`, `VIP_`, or `IS_VIP_`, or reuse a WordPress constant name such as `DB_NAME`. Values are strings, limited to 4096 bytes each and 16384 bytes for all of an environment's variables. Pass a default to `vip_get_env_var()` for variables that may be unset.

## Queries and remote requests

Prefer bounded `WP_Query` calls; use `no_found_rows` when pagination is unnecessary. With `get_posts()`, set `suppress_filters` to `false`. Avoid unbounded queries, random SQL ordering, and high-volume counters in post meta.

VIP provides cached alternatives for some [uncached functions](https://docs.wpvip.com/caching/uncached-functions/), including `wpcom_vip_attachment_url_to_postid()` and `wpcom_vip_url_to_postid()`. Use `WP_Query` instead of deprecated `get_page_by_title()`; `wpcom_vip_get_page_by_title()` is also deprecated.

For unavoidable frontend HTTP GETs, `vip_safe_wp_remote_get()` takes positional arguments:

```php
vip_safe_wp_remote_get( $url, $fallback_value, $threshold, $timeout, $retry, $args );
```

Request options such as headers belong in the sixth argument, not the second. Cache results; prefer cron for remote work. PHPCS may flag deliberate background requests or timeouts: explain a justified exception inline using the reported sniff code.

## Cache and asset changes

Object-cache entries and transients may be evicted; they cannot hold the only copy of data. Keep entries below 1 MB. Transients are in the object cache, not `wp_options`; do not query the database for them. VIP does not support `wp_cache_flush_group()`; delete specific keys or version them.

A response that sends `Set-Cookie` is not cached at the edge, so code that sets a cookie on every request turns off page caching for those pages.

Deploys do not generally purge page/object caches. Handle existing cached-data formats. For new invalidation behavior, use targeted `wpvip_purge_edge_cache_for_url()` or the related post/term helpers. Custom post-type archives may need explicit purge coverage.

Use build-generated asset versions or a release version, not production `filemtime()`. Account for cached pages still referencing old hashed assets after a deploy. Do not autoload large or rarely used options.

## Cron and bulk commands

Use `wp_schedule_event()` for recurring work and guard against duplicate scheduling. Avoid frontend writes when registering events. VIP Cron Control replaces `/wp-cron.php`; keep events cheap and recurring intervals at least 15 minutes.

Bulk WP-CLI commands should be bounded, resumable or idempotent, and offer a dry run. `WPCOM_VIP_CLI_Command` supplies bulk-operation and in-memory cleanup helpers; the class exists only under WP-CLI, so guard command declarations and registration. Do not use an increasing offset while changing the field used to select rows.

## Files and media

Use media APIs for persistent uploads. VIP File System directory enumeration does not behave like a local filesystem; use attachment metadata instead. Only original images are stored: generate resized URLs through WordPress image APIs rather than looking for thumbnail files.

Temporary files use `get_temp_dir()` or `wp_tempnam()` and must be cleaned up. Valid file operations can still trigger PHPCS; suppress only the reported sniff with a reason identifying the trusted temp/uploads path. Files uploaded through the stream wrapper need attachment records for normal deletion workflows.

## Rewrites and operational follow-up

A deploy does not flush rewrite rules. When adding a post type, taxonomy, or rewrite, identify the required post-deploy flush through WP Admin or `vip @app.env -- wp rewrite flush`; multisite needs the appropriate `--url`. Do not flush on ordinary frontend requests. Do not execute production commands merely because this reference mentions them.

There is no application `.htaccess` or custom NGINX configuration. Upload URLs go to the VIP File System; PHP cannot handle them like normal application routes. Consult the [file redirect limitations](https://docs.wpvip.com/redirects/limitations-for-files/) only if the task involves static-file routes.

VIP forces `WP_DEBUG_LOG` off. For runtime debugging, use existing Dashboard Runtime Logs or VIP CLI log access rather than searching for `debug.log`.

A custom error page lives at `.wpvip/errors/site-unavailable.html`: self-contained HTML under 150 KB. CI builds must include `.wpvip/` rather than exclude it through `.deployignore`; enabling the page also requires a Dashboard setting.

## Email

Use `wp_mail()` only for low-volume mail to fixed recipients such as site admins. Do not send to user-supplied addresses or send bulk mail; [use a third-party email service](https://docs.wpvip.com/wordpress-on-vip/email/) for that. Attaching a VIP File System file requires `define( 'USE_VIP_PHPMAILER', true );` in `vip-config.php`.

## Code Analysis Bot

The bot scans files changed in open pull requests. Exclude vendored code and built-asset directories by listing one path per line in `.vipgoci_phpcs_skip_folders`, with a matching `<exclude-pattern>` in `.phpcs.xml.dist` for local runs. The bot's 15,000-line skip does not cover minified bundles, which are only a few long lines. Label pure vendored-code updates `skip-phpcs-scan`; PHP linting still runs.

## Further reference

Use [VIP documentation](https://docs.wpvip.com/) when an unresolved platform question affects the task. For a new plugin, the [incompatibility list](https://docs.wpvip.com/plugins/incompatibilities/) can help assess suitability. Do not browse these links routinely or re-verify unrelated platform facts.
