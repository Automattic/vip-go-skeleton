# AGENTS.md

Guidance for AI coding agents working in this repository. [README.md](README.md) is the human-facing overview; this file covers what an agent needs to make safe, reviewable changes to a WordPress VIP application. `CLAUDE.md` only points here; edit this file, not that one.

## Critical rules

- **MUST NOT** commit secrets: private API keys, tokens, passwords, or other credentials. Read them with `vip_get_env_var()`.
- **MUST NOT** commit personal data: names, emails, user or account IDs, or other details about end users or customers taken from bug reports or support conversations, in code, fixtures, comments, commit messages, branch names, or pull request text. Use neutral placeholders such as `example.com`, and scrub those details from error messages you quote. Identifiers the site publishes anyway are fine: its own domains and site IDs, `ads.txt` publisher IDs, analytics measurement IDs, and keys meant for browser code.
- **MUST NOT** patch third-party code in place: `themes/twentytwentyfive/`, vendored plugins, and any plugin's or theme's own `vendor/` or `node_modules/`. Customize through hooks or a deliberate fork. To update third-party code, replace its whole directory from the upstream release in a pull request of its own.
- **MUST NOT** vendor plugins the platform already ships (Jetpack, Akismet, Query Monitor, Two Factor, and the others under "Built-in" in [.gitignore](.gitignore), which also blocks a few retired ones). They are gitignored; never override that with `git add -f`.
- **MUST NOT** commit directly to a deploy branch (`production`, `develop`, or any `*-built` branch). Merging a pull request triggers a deploy.
- **MUST** assume every file inside the deployed directories ships and is web-accessible (except `private/`). [.deployignore](.deployignore) is only honored by VIP's GitHub Actions build into a `-built` branch; with Default Deployment, a `tests/` folder inside a theme or plugin is public. Keep test suites and fixtures in a root-level directory such as `tests/`, which never deploys.
- **MUST NOT** write to the local filesystem outside the system temp directory (`get_temp_dir()`). Persistent files go to the uploads path on the VIP File System. **MUST NOT** write to the database on frontend `GET` requests, including REST responses to frontend requests; pages are served from the edge cache, so those writes run unpredictably and add load.
- **MUST** escape output, sanitize input, and check nonces and capabilities on every state-changing handler.

## What this repository is

This is the [WordPress VIP skeleton](https://docs.wpvip.com/wordpress-skeleton/): the application-code layer of a WordPress site hosted on the VIP Platform. It is **not** a full WordPress install. WordPress core, `wp-config.php`, `mu-plugins/`, drop-ins, and the uploads directory are provided by the platform and must never be committed here.

Only these root directories are deployed: `client-mu-plugins/`, `images/`, `languages/`, `plugins/`, `private/`, `themes/`, `vip-config/`. All of them are web-accessible except `private/`. New root directories do not deploy. One exception, `.wpvip/errors/`, is covered in the table. `docs/` is for documentation only and never deploys.

| Path | Purpose | Agent rules |
| --- | --- | --- |
| `client-mu-plugins/` | Always-on code, loaded before regular plugins. Every top-level PHP file loads automatically; subdirectories do not. [`plugin-loader.php`](client-mu-plugins/plugin-loader.php) is the conventional place for `wpcom_vip_load_plugin()` calls and for `require __DIR__ . '/dir/dir.php'` lines that load subdirectory code. | Put custom site logic and plugin activation here. Do not `require` a top-level file from `plugin-loader.php`; it already autoloads, and a plain `require` can load it twice. Plugins loaded with `wpcom_vip_load_plugin()` never fire `register_activation_hook()` or `register_deactivation_hook()`; see Platform constraints. |
| `plugins/` | Regular plugins, decompressed, committed in full. | Prefer VIP MU plugin functionality before adding a plugin. `hello.php` is WordPress's shipped sample: delete it or leave it, never fix it in place. |
| `themes/` | Themes. `twentytwentyfive/` is upstream WordPress, kept for testing. | Build custom themes alongside it. |
| `vip-config/` | [`vip-config.php`](vip-config/vip-config.php) runs immediately after `wp-config.php`. On multisite, `client-sunrise.php` here runs during sunrise. | `vip-config.php`: pure PHP only, no WordPress core functions; `vip_get_env_var()` is available. Constants and early config only. For domain redirects, copy the [vip-config redirect example](https://docs.wpvip.com/redirects/domain-redirects-in-vip-config-php/): it excludes `/cache-healthcheck?` and WP-CLI, uses lowercase domains, and carries the `phpcs:ignore` for `$_SERVER` reads. Without the `/cache-healthcheck?` exclusion the redirect breaks platform health checks, and without the WP-CLI check it redirects CLI commands. `client-sunrise.php` runs on every request during multisite bootstrap, before mu-plugins, plugins, and the theme. Use it only for code that must run that early: pure PHP where possible, limited to specific domains or conditions, and with no database or other persistent-data access ([sunrise guidance](https://docs.wpvip.com/wordpress-on-vip/multisites/sunrise-php/)). |
| `private/` | Files readable by code but not served over HTTP. | Reference files via the `WPCOM_VIP_PRIVATE_DIR` constant (production resolves it outside the repo tree), never a relative path, and not from `vip-config.php`. Suitable for config and data files; prefer environment variables for secrets so they stay out of git history. |
| `images/` | Small static image assets such as site icons. | Anything large or numerous belongs in the media library. |
| `languages/` | `.po`/`.mo` files. | Translations only. |
| `docs/` | Project documentation. | Do not create new docs files unless asked. |
| `.wpvip/errors/` | [Custom error page](https://docs.wpvip.com/infrastructure/edge-servers/custom-error-pages/). Not a web path. | Ships only `site-unavailable-sample.html`; rename it to `site-unavailable.html` to use it. One self-contained HTML file under 150 KB, with CSS, JS, and Base64 images inline. Repos using a CI build must also remove `.wpvip/` from `.deployignore`, or the file never deploys. Tell the user to enable it in the VIP Dashboard after deploy. |

## Environment and tooling

- **PHP** 8.2+ (see `composer.json` and `testVersion` in `.phpcs.xml.dist`). The platform controls the WordPress version; `minimum_supported_wp_version` in `.phpcs.xml.dist` (currently 6.8) is a PHPCS setting, not a runtime requirement.
- **Composer** is used only for dev tooling (PHPCS and standards). Do not add runtime PHP dependencies at the repo root; a plugin that needs Composer packages vendors them inside its own directory.
- **Node**: no `package.json`, `package-lock.json`, or `node_modules/` at the repo root. Per-theme or per-plugin `package.json` is fine, but built assets must be committed or produced by a CI build into a `-built` branch.
- **Indentation** is tabs for PHP/JS/CSS per [.editorconfig](.editorconfig). YAML files (`.yml`, `.yaml`) use 2 spaces.
- **Debugging**: `WP_DEBUG_LOG` is forced off on VIP, so there is no `debug.log`. Read PHP errors in the VIP Dashboard's Runtime Logs panel or with `vip @app.env logs`; locally, `vip dev-env logs --slug=vip-local --service=php`. Prefer `trigger_error()` over `error_log()`; VIP's handler adds a backtrace. PHPCS flags both (`WordPress.PHP.DevelopmentFunctions.error_log_trigger_error` is a warning, `error_log_error_log` an error): remove debug calls before merging, and suppress a deliberate log line inline with a reason.
- **Local environment**: the VIP Local Development Environment via `vip-cli`, or the Codespaces config in [.devcontainer/](.devcontainer/):

  ```bash
  vip dev-env create --slug=vip-local
  vip dev-env update --slug=vip-local --app-code=/path/to/this/repo
  vip dev-env start --slug=vip-local
  vip dev-env exec --slug=vip-local -- wp option get siteurl
  ```

  Directory mapping inside the running site: `themes/` → `wp-content/themes/`, `plugins/` → `wp-content/plugins/`, `client-mu-plugins/` → `wp-content/client-mu-plugins/` (constant `WPCOM_VIP_CLIENT_MU_PLUGIN_DIR`). `wp-content/mu-plugins/` holds VIP's platform plugins, not yours.

## Checks to run, and when

The repository ships one check: PHPCS with the `WordPress-VIP-Go` and `PHPCompatibilityWP` standards, configured in [.phpcs.xml.dist](.phpcs.xml.dist). The VIP Code Analysis Bot runs the same standards on every pull request.

```bash
composer install
```

**Scope checks to what you changed.** The bot only scans files altered in a pull request and only comments on changed lines. Always run PHPCS from the repository root and pass a path; bare `vendor/bin/phpcs` scans every configured directory, including from inside a theme. Run from the root, PHPCS uses only the root ruleset. A theme or plugin with its own ruleset (see Code style) needs `--standard`, and the changed-files pipeline below does not apply it.

```bash
# Every PHP and JS file changed on this branch, committed or not, plus new untracked files.
# Replace `origin/production` with your base branch. A `fatal:` line means the base ref was not found.
# No output at all means no files matched; PHPCS prints a progress line whenever it scans.
base=$(git merge-base origin/production HEAD) && { git diff -z --name-only --diff-filter=ACMR "$base" -- '*.php' '*.js'; git ls-files -z --others --exclude-standard -- '*.php' '*.js'; } | xargs -0 -r vendor/bin/phpcs

# Or a single directory you are working in
vendor/bin/phpcs themes/my-theme/

# A theme or plugin with its own nested ruleset
vendor/bin/phpcs --standard=themes/my-theme/.phpcs.xml.dist themes/my-theme/
```

`phpcbf` can apply auto-fixable sniffs. With `WordPress-VIP-Go` alone it fixes only loose comparisons (`==` and `!=` to `===` and `!==`), stray closing `?>` tags, whitespace at the start or end of a file, and curly-brace offsets (`$s{0}` to `$s[0]`). The strict-comparison rewrite changes behavior, so review every change. It becomes a formatting tool once `WordPress-Extra` is enabled:

```bash
vendor/bin/phpcbf path/to/changed/file.php
```

Syntax-check PHP you wrote (the bot lints with each PHP version used by the app's environments):

```bash
php -l path/to/changed/file.php
```

Skip checks entirely when a change touches only file types the bot [auto-approves](https://docs.wpvip.com/vip-code-analysis-bot/auto-approvals/): stylesheets (`.css`, `.scss`, `.sass`, `.less`, `.pcss`, `.styl`), data and text (`.json`, `.yml`, `.yaml`, `.ini`, `.md`, `.mdown`, `.txt`, `.csv`, `.lock`, `.map`, `.pdf`), translations (`.po`, `.pot`, `.mo`), fonts, raster images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.ico`), `.mp4`, and `.gz`. `.html`, `.svg`, `.webp`, `.xml`, and `.htaccess` are not on that list; an SVG is auto-approved only when the bot's SVG scanner finds no issues.

### Avoiding unnecessary test and scan work

- **Do not run PHPCS on third-party code.** `.phpcs.xml.dist` already excludes `twentytwentyfive`, `vendor`, and `node_modules`. Add an `<exclude-pattern>` for each third-party plugin directory you vendor, since `plugins/` is otherwise scanned in full. Findings in code you cannot modify are not work items. Two shipped files already report findings: `plugins/hello.php` (escaping errors) and the commented-out example in `client-mu-plugins/plugin-loader.php`. Do not fix either.
- **Do not add tests for third-party plugins or upstream themes.** Test only custom code.
- **Do not run PHPUnit for every change.** If a plugin or theme has a test suite, run only the suite for the code you touched. There is no root-level test runner.
- **Keep bot-side scanning lean** with VIP's repo-root config files:
  - `.vipgoci_phpcs_skip_folders` and `.vipgoci_lint_skip_folders`: one directory path per line (no globs, no regex), e.g. `tests/fixtures` or `plugins/third-party-plugin`. Use these for vendored code and for test fixtures with intentional syntax errors.
  - `.vipgoci_options` (JSON) to tune the bot, e.g. `{"skip-draft-prs": true}`, or `"phpcs-sniffs-exclude"` for a sniff that is consistently a false positive. Keep `phpcs-severity` at `1` to match the local config.
  - Label a PR `skip-phpcs-scan` only for pure vendored-code updates; PHP linting still runs.
  - The bot skips files over 15,000 lines. Minified bundles are usually a few very long lines, so they are scanned: add built-asset directories such as `themes/my-theme/build` to `.vipgoci_phpcs_skip_folders` and to an `<exclude-pattern>` in `.phpcs.xml.dist`, and do not try to make built files pass PHPCS.
- **Suppress a false positive inline rather than globally.** Use the full sniff code and always give a reason:

  ```php
  // phpcs:ignore WordPress.Security.NonceVerification.Recommended -- read-only query var, no state change.
  $active_tab = isset( $_GET['tab'] ) ? sanitize_key( $_GET['tab'] ) : 'general';
  ```

  Use `phpcs:disable` / `phpcs:enable` pairs for blocks. Never suppress security sniffs without explaining why the code is safe.

## Coding rules the bot and your reviewers enforce

These come from the [VIP Code Analysis Bot](https://docs.wpvip.com/vip-code-analysis-bot/) and VIP's PHPCS [errors](https://docs.wpvip.com/php_codesniffer/errors/) and [warnings](https://docs.wpvip.com/php_codesniffer/warnings/).

### Security

- Validate and sanitize input early; escape output late, at the point of rendering. Never trust `$_GET`, `$_POST`, `$_REQUEST`, `$_SERVER`, `$_COOKIE`, database values, or API responses.
- Escape with the function matching the context: `esc_html()`, `esc_attr()`, `esc_url()`, `esc_js()`, `wp_kses_post()` / `wp_kses()`. Use `rawurlencode()` for URL parameters.
- Every form handler and AJAX action that changes state needs a nonce check (`check_admin_referer()`, `check_ajax_referer()`, `wp_verify_nonce()`) and a capability check (`current_user_can()`). REST routes get their capability check in `permission_callback`; use `'__return_true'` only for routes meant to be public. Core verifies the nonce on cookie-authenticated REST requests only when the client sends one: frontend JS must send an `X-WP-Nonce` header from `wp_create_nonce( 'wp_rest' )` (or use `@wordpress/api-fetch`), or the request runs as a logged-out user.
- No `eval()`, `extract()`, `create_function()`, dynamic `include`/`require` from user input, `ini_set()`, `error_reporting()`, or `date_default_timezone_set()`.
- In JavaScript, do not insert untrusted HTML via `.html()` or `innerHTML`.
- Redirect with `wp_safe_redirect()` and allow external destinations through the `allowed_redirect_hosts` filter; never pass a user-influenced URL to `wp_redirect()`. Call `exit` after either.
- `vip_get_env_var( 'NAME', 'default' )` works even inside `vip-config.php`. Set values are always strings; an unset variable returns the default unchanged. [Environment variable](https://docs.wpvip.com/infrastructure/environments/manage-environment-variables/) names cannot start with `WPCOM_`, `VIP_`, or `IS_VIP_` or reuse a WordPress constant name such as `DB_NAME`, and a value is limited to 4096 bytes (16384 bytes for all of an environment's variables).

### Performance and caching

- Avoid the [uncached functions](https://docs.wpvip.com/caching/uncached-functions/). Use the VIP equivalents: `wpcom_vip_attachment_url_to_postid()`, `wpcom_vip_count_user_posts()`, `wpcom_vip_get_adjacent_post()` (replaces `get_adjacent_post()`, `get_previous_post()`, `get_next_post()`, `previous_post_link()`, `next_post_link()`), `wpcom_vip_wp_oembed_get()`, `wpcom_vip_url_to_postid()`. Old-slug redirects are already cached by the platform, so add nothing for them (the `wpcom_vip_old_slug_redirect()` named in the docs is deprecated). Replace `get_page_by_title()` with `WP_Query`; ignore the sniff message that suggests `wpcom_vip_get_page_by_title()`, which is itself deprecated.
- Remote requests on page load: use `vip_safe_wp_remote_get()` and cache the result in the object cache or a transient. Its arguments are positional, `( $url, $fallback_value, $threshold, $timeout, $retry, $args )`: the timeout (1 to 5 seconds, default 1) is the fourth, and request options such as headers go in `$args`, the sixth. A `wp_remote_get()`-style options array passed second is treated as the fallback value. Never use cURL directly. Prefer doing remote work in cron and reading cached results on the frontend. In cron, `wp_remote_get()` with a longer timeout is acceptable, but PHPCS reports a `timeout` above 3 as `WordPressVIPMinimum.Performance.RemoteRequestTimeout.timeout_timeout` and warns with `WordPressVIPMinimum.Functions.RestrictedFunctions.wp_remote_get_wp_remote_get`; suppress both inline with a reason such as `-- runs in cron`.
- Prefer `WP_Query` over `get_posts()`. If you use `get_posts()`, pass `'suppress_filters' => false`; the bot warns regardless, so suppress it inline with `// phpcs:ignore WordPressVIPMinimum.Functions.RestrictedFunctions.get_posts_get_posts -- suppress_filters is false.`
- Always set `posts_per_page` to a finite number; `-1` passes PHPCS but can time out once production data grows. Add `'no_found_rows' => true` when pagination is not needed. Avoid `post__not_in`, `ORDER BY RAND()` (use `vip_get_random_posts()`), category/tag `AND` operations, and large `meta_query` result sets. Set `'include_children' => false` on taxonomy queries where children are not required.
- The edge [page cache](https://docs.wpvip.com/caching/page-cache/) keeps `200` and `301` responses for 30 minutes and REST `GET` responses for 1 minute (raise with `wpcom_vip_rest_read_response_ttl`; avoid going below 1 minute). Logged-in and other authenticated requests bypass it, and any response that sends `Set-Cookie` is not cached. Publishing or updating a post purges only its own URL and comments feed, its term archives and their feeds, the home page, the posts page, and the RSS feed. A custom post type's archive is not purged; add it with the `wpcom_vip_cache_purge_{$post_type}_post_urls` filter. For output driven by options, menus, or custom endpoints, purge with `wpvip_purge_edge_cache_for_url()` (or `_for_post()` / `_for_term()`); purges run asynchronously on `shutdown`.
- Bump the `$ver` argument of `wp_enqueue_script()` / `wp_enqueue_style()` whenever the file changes; VIP concatenates assets and caches them by version. Do not use `filemtime()` for `$ver` in production; take it from the `version` in the `*.asset.php` file that `@wordpress/scripts` generates, or from a version constant bumped with each release. Keep old hashed build files for at least 30 minutes after a deploy, since cached pages still reference them.
- Disable autoload unless the option is read on every request: `add_option( 'x', $value, '', false )` (autoload is the fourth argument; the third is deprecated) and `update_option( 'x', $value, false )`. `update_option()` leaves autoload unchanged when the value has not changed. If the compressed `alloptions` value reaches 1 MB the site returns `503` with `Error 1024 (alloptions)`.
- Cron events must run no more often than every 15 minutes and must be cheap. The `CronInterval` sniff computes literals and time-constant arithmetic; when it cannot (variables, custom constants, callbacks defined elsewhere) it reports `ChangeDetected`, so check those intervals by hand. `/wp-cron.php` is disabled; [Cron Control](https://docs.wpvip.com/wordpress-on-vip/cron-control/) runs due events, by default one event per action at a time. Schedule recurring work with `wp_schedule_event()`, not repeated `wp_schedule_single_event()` calls, and do not run WP-CLI commands inside a cron callback. Activation hooks never fire on VIP, so schedule from `admin_init` behind `if ( ! wp_next_scheduled( 'my_hook' ) )`; the one write then happens in an admin request, not on the frontend.
- Custom WP-CLI commands for bulk work follow VIP's [commands-at-scale guidance](https://docs.wpvip.com/vip-cli/wp-cli-with-vip-cli/cli-commands-at-scale/): extend `WPCOM_VIP_CLI_Command` and use its static helpers, `self::vip_inmemory_cleanup()` every 50 to 100 posts and `self::start_bulk_operation()` / `self::end_bulk_operation()` around writes. That class exists only when WP-CLI runs, so declare the command class and call `WP_CLI::add_command()` only inside `if ( defined( 'WP_CLI' ) && WP_CLI )`, or every web request fatals. Offer `--dry-run`, `sleep()` between batches, and make the command idempotent or resumable. Do not page with an increasing offset while changing the field the query filters on; that skips rows.
- Do not use post meta as a counter for high-volume events (race conditions under cache).
- Cache expensive computations with `wp_cache_get()` / `wp_cache_set()` using grouped keys. Use an expiry of 300 seconds or more (the `LowExpiryCacheTime` sniff flags anything lower; `0` means no expiry). Avoid writing to the object cache on every request, and keep each entry under 1 MB. Transients are stored in the [object cache](https://docs.wpvip.com/caching/object-cache/), not `wp_options`; both can be evicted at any time, so never keep the only copy of data there, and never query the database for transients. `wp_cache_flush_group()` does nothing on VIP (`wp_cache_supports( 'flush_group' )` is `false`); delete specific keys or put a version number in the key instead.

### Platform constraints

- Web containers are read-only. The system temp directory (`get_temp_dir()` or `wp_tempnam()`, not a hard-coded `/tmp`) is writable but lives only for the current request; clean up with `unlink()`. Persistent files belong in the uploads directory on the VIP File System: prefer the media APIs (`wp_upload_bits()`, `media_handle_sideload()`), or use `wp_get_upload_dir()` paths with PHP file functions (a stream wrapper handles them) or `WP_Filesystem`. Create directories with `wp_mkdir_p()`; `mkdir()`, `rmdir()`, and `chmod()` are PHPCS errors. Never hard-code `wp-content/uploads/`. Always create an attachment post for files written through the stream wrapper; files without one cannot be deleted without VIP assistance.
- On the [VIP File System](https://docs.wpvip.com/vip-file-system/media-uploads/), `glob()`, `scandir()`, `opendir()`, and `list_files()` return empty results or `false`, `file_exists()` and `is_dir()` can return wrong answers, and every file operation takes at least 200 ms. Read attachment data from the database (`wp_get_attachment_metadata()`) instead of probing files. Only the original image is stored, so no `-300x300` intermediate files exist: get image URLs from `wp_get_attachment_image()` / `wp_get_attachment_image_src()`, or resize with query arguments such as `?w=300&h=200&crop=1`.
- Direct file functions warn even on valid paths. Suppress each inline with its full code and a reason such as `-- path is from get_temp_dir()` or `-- VIP File System uploads path`:
  - `file_put_contents()`, `fwrite()`, `unlink()`, `rename()`, `touch()`: `WordPressVIPMinimum.Functions.RestrictedFunctions.file_ops_<function>`, e.g. `file_ops_fwrite`.
  - `fopen()`: `WordPress.WP.AlternativeFunctions.file_system_operations_fopen`.
  - `file_get_contents()` whose argument has no string literal, such as `file_get_contents( $path )`: `WordPressVIPMinimum.Performance.FetchingRemoteData.FileGetContentsUnknown`. A path such as `WPCOM_VIP_PRIVATE_DIR . '/data.json'` is not flagged.
- A deploy does not flush rewrite rules, the object cache, or the page cache (except for changed static files). After adding a custom post type, taxonomy, or rewrite rule, do not call `flush_rewrite_rules()` in code; tell the user to flush after deploy from WP Admin > VIP > Rewrite Rules or with `vip @app.env -- wp rewrite flush`. On multisite that command flushes only the site named by `--url` (the main site by default), so it must run once per site with `--url=`. Code that changes the shape of cached data must handle old entries, for example by versioning the cache key.
- There is no `.htaccess` or custom NGINX configuration. Put [redirects](https://docs.wpvip.com/redirects/) in PHP: `vip-config.php` for domains, plugin or theme code otherwise. A file at a root URL such as `/ads.txt` must live in the theme and be served through a rewrite rule; a file at the repository root never deploys. Requests under `/wp-content/uploads/` go to the VIP File System, so PHP cannot rewrite or redirect them; the only PHP involvement is the access check when Access-Controlled Files is enabled. URLs matching `\.(css|js|jp(e)?g|gif|png|swf|ico)$` are handled by NGINX first: PHP sees them only after a 404, so it can 301-redirect them but not serve them through a rewrite rule ([file limitations](https://docs.wpvip.com/redirects/limitations-for-files/)). Other extensions, such as `.xml` sitemaps, work with normal rewrite rules.
- Detect the environment with the platform-defined `VIP_GO_APP_ENVIRONMENT` constant, guarded so code still runs where it is undefined (unit tests, non-VIP local setups): `defined( 'VIP_GO_APP_ENVIRONMENT' ) && 'production' === VIP_GO_APP_ENVIRONMENT`. Never define it in `vip-config.php` or application code; the platform sets it (a non-VIP local setup defines it as `local` in its own `wp-config.php`). `wp_get_environment_type()` returns only `production`, `staging` (every custom environment name), `development`, or `local`, and does not work in `vip-config.php`.
- Use `wp_mail()` only for low-volume mail to fixed recipients such as site admins. Never let it send to user-supplied addresses or send bulk mail; use a third-party email service for that. The bot warns on every call (`WordPressVIPMinimum.Functions.RestrictedFunctions.wp_mail_wp_mail`); suppress it inline with a reason naming the fixed recipients. Attaching a VIP File System file requires `define( 'USE_VIP_PHPMAILER', true );` in `vip-config.php`.
- No PHP sessions, no `$_SESSION`. Do not use `setcookie()`, `$_COOKIE`, or `$_SERVER['HTTP_USER_AGENT']` to vary output; the page cache serves one response to all anonymous visitors. Use the [Cache Personalization API](https://docs.wpvip.com/caching/page-cache/customize-behavior/cache-personalization-api/) or client-side logic when responses must vary.
- Plugins and themes cannot be installed, updated, or deleted from wp-admin; commit them to the repository. Activate plugins in code with `wpcom_vip_load_plugin()`. On multisite this network-activates unless gated with `get_current_blog_id()`. For a plugin that needs `register_activation_hook()` to run, use two pull requests. The first adds only the plugin files. After it deploys, tell the user to activate the plugin from the wp-admin Plugins screen in each environment (Network Admin on multisite). The second pull request adds the `wpcom_vip_load_plugin()` call.
- There is no FTP, SSH, or shell on production. WP-CLI runs through `vip-cli` (`vip @app.env -- wp ...`).
- Check [plugin incompatibilities](https://docs.wpvip.com/plugins/incompatibilities/) before adding a plugin.

## Code style

- Follow the [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/): tabs, Yoda conditions, spaces inside parentheses, snake_case functions and variables, `===` over `==`. `WordPress-VIP-Go` enforces mostly security and performance sniffs plus a few hygiene checks (commented-out code, PHP closing tags, `===`), not formatting. `WordPress-Extra` and `WordPress-Docs` are present but commented out in `.phpcs.xml.dist`.
- Prefix all global functions, classes, hooks, options, and transients with a project-specific prefix, and internationalize user-facing strings with the theme or plugin text domain. To have PHPCS check both, add a nested `.phpcs.xml.dist` to the custom theme or plugin:

  ```xml
  <?xml version="1.0"?>
  <ruleset name="My Theme">
  	<rule ref="../../.phpcs.xml.dist"/>
  	<rule ref="WordPress.NamingConventions.PrefixAllGlobals">
  		<properties>
  			<property name="prefixes" type="array">
  				<element value="my_theme"/>
  			</property>
  		</properties>
  	</rule>
  	<rule ref="WordPress.WP.I18n">
  		<properties>
  			<property name="text_domain" type="array">
  				<element value="my-theme"/>
  			</property>
  		</properties>
  	</rule>
  </ruleset>
  ```

- Custom plugins: one per directory in `plugins/`. `wpcom_vip_load_plugin( 'foo' )` resolves `plugins/foo/foo.php`, then `plugins/foo/plugin.php`; use `wpcom_vip_load_plugin( 'foo/main.php' )` for any other main-file name.
- Keep PHP compatible with every PHP version used by the application's environments. Do not use syntax newer than the `testVersion` floor in `.phpcs.xml.dist` without raising it deliberately.

## Git and pull requests

- Deploy branches map to environments (commonly `production` and `develop`; CI builds push to `<branch>-built`). Branch feature work from `production`, as VIP's [build and deploy](https://docs.wpvip.com/code-deployment/default-deployment/build-and-deploy/) flow does, even when the pull request first targets `develop` for testing; a branch cut from `develop` carries unreleased commits into the later production pull request. Open a pull request, let the bot and a human review, then merge. Merging triggers a deploy, either directly (Default Deployment) or through a CI build that pushes to the `-built` branch.
- The bot only analyzes open pull requests with a commit in the last 7 days; commits pushed straight to a deploy branch are never scanned. It never re-posts the same feedback. Address every bot comment, suppress it inline with a reason, or dismiss the review in GitHub when it is a false positive.
- Keep pull requests small and single-purpose. Separate vendored plugin or theme updates from custom-code changes, and label vendored-only updates `skip-phpcs-scan`.
- Non-functional PHP changes (whitespace, comments) and the auto-approved file types listed under "Checks to run, and when" are approved by the bot without review; batch them separately from logic changes.
- Do not commit the root `vendor/`, any `node_modules/`, `.phpcs.xml` (local override), `.env`, or OS files; root `.gitignore` already blocks these. A plugin's or theme's own `vendor/` is not ignored: commit it when that code needs it at runtime.

## When in doubt

- Prefer a VIP MU plugin feature or helper over a new dependency.
- Prefer environment variables over constants for anything that differs per environment.
- Prefer cached, bounded queries over clever ones.
- Some changes need VIP Support, not code: deleting VIP File System files that have no attachment post, changing `CRON_CONTROL_JOB_CONCURRENCY_LIMIT` or `CRON_CONTROL_JOB_QUEUE_SIZE`, and letting static asset URLs outside uploads reach PHP. Stop and tell the user to open a support request instead of working around these in code.
- Reference documentation: https://docs.wpvip.com/ (skeleton, code analysis bot, PHPCS, caching, security, VIP File System, local development).
