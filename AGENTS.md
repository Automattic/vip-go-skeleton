# Agent instructions

This is the application-code layer of a WordPress VIP site, not a full WordPress installation.

## Keep work bounded

- Follow the user's requested scope and the customer's existing project conventions. Do not treat the original skeleton layout or examples as a reason to reorganize an established repository.
- Inspect the relevant code and configuration; do not inventory the whole repository or read every linked document. Use [VIP platform reference](docs/vip-platform-reference.md) only when a specific platform question needs it, and read only the relevant section. Links are resources, not a checklist.
- Preserve unrelated user changes. Do not fix pre-existing warnings, reformat unrelated code, add tooling, tighten lint rules, or create plans/reports/docs unless the task needs them or the user asks.
- Reuse available tools and environments. Install dependencies only if a necessary check requires them. When runtime validation is needed, use the [VIP Local Development Environment](https://docs.wpvip.com/vip-local-development-environment/) (`vip dev-env`), which runs VIP's platform MU plugins, rather than a generic WordPress setup; reuse an existing environment before creating one. If tooling is unavailable, report the limitation instead of repeatedly trying setup alternatives.
- Some changes need VIP Support rather than code: deleting VIP File System files that have no attachment record, changing the restricted Cron Control limits (`CRON_CONTROL_JOB_CONCURRENCY_LIMIT`, `CRON_CONTROL_JOB_QUEUE_SIZE`), or letting static asset URLs outside uploads reach PHP. Tell the user to open a support request instead of working around these in code.
- Once the requested work and relevant validation are complete, stop. Summarize the result and any material validation gap briefly. Do not add review rounds, CI polling, commits, PRs, merges, or deployments unless requested or already part of the authorized task.

## Platform boundaries

- Never commit credentials or private customer data from reports or support conversations. Use neutral fixtures and `vip_get_env_var()` for secrets.
- WordPress core, `wp-config.php`, platform `mu-plugins/`, drop-ins, and uploads are provided by VIP; do not commit them here. Do not vendor platform-provided plugins such as Jetpack or Akismet; see the built-in entries in `.gitignore` when adding a plugin.
- Application directories deployed by VIP are `client-mu-plugins/`, `images/`, `languages/`, `plugins/`, `private/`, `themes/`, and `vip-config/`. Treat their contents as public except `private/`. Other root directories do not deploy, apart from the custom error-page mechanism in `.wpvip/errors/`. `.deployignore` applies to VIP's CI build flow, not Default Deployment; keep new tests and private fixtures outside deployed directories.
- Top-level PHP files in `client-mu-plugins/` load automatically; subdirectory code needs a loader. Do not require a top-level file again. `wpcom_vip_load_plugin( 'foo' )` loads `plugins/foo/foo.php` or `plugins/foo/plugin.php`; use a file path for other entry points. It does not run activation hooks.
- `vip-config/vip-config.php` runs before WordPress APIs are available; use pure PHP and early configuration (`vip_get_env_var()` is available). Access private files through `WPCOM_VIP_PRIVATE_DIR` after bootstrap, not relative paths. Domain redirects must exclude WP-CLI and `/cache-healthcheck?` requests.
- At runtime, local storage is read-only except temporary storage from `get_temp_dir()`; persistent uploads use the VIP File System and media APIs. Do not perform database writes on frontend GET requests or assume filesystem directory listings work for uploads.
- Do not patch vendored third-party code in place. Use hooks, an intentional fork, or an upstream release update. Do not lint, reformat, or add tests for third-party code merely because it is present.

## Checks

Choose checks for the behavior changed, not for the bot's auto-approval list. Read-only reviews and prose-only edits do not need application checks. Configuration, dependency, style, and build changes may need their own focused validation.

For custom PHP/JS changes, use existing PHPCS tooling from the repository root with explicit files touched by the task. The root ruleset is `.phpcs.xml.dist`; if the affected component has its own ruleset, pass that instead. These are alternatives, not successive checks:

```sh
vendor/bin/phpcs path/to/changed.php path/to/changed.js
vendor/bin/phpcs --standard=themes/my-theme/.phpcs.xml.dist themes/my-theme/changed.php
```

- Never run bare `vendor/bin/phpcs`; it scans all configured directories. Do not automatically include all branch changes or untracked files. Use broader scope only for a requested whole-PR review or a concrete cross-cutting risk.
- Syntax-check changed PHP with `php -l path/to/changed.php` unless an existing check already covers syntax. Run the smallest relevant existing test selection for behavior changes. The skeleton has no root PHPUnit runner; do not create one for routine validation.
- Run relevant checks after the final edit. Reuse results while their inputs remain unchanged; repeat or broaden checks only after relevant changes, failures, or a concrete unresolved risk. An unavailable check is a reported limitation, not a pass.
- Fix findings introduced by the task. For a genuine false positive, use a narrow inline suppression with the sniff code and a safety explanation; do not disable checks globally to get a pass. Do not auto-fix blindly: `phpcbf` can change comparison semantics.

## Code and delivery

- Follow existing WordPress style, `.editorconfig`, project prefixes, text domains, and configured PHP compatibility. Root Composer dependencies are development tools; runtime dependencies must be included in a deployed component or its build output. Reuse the customer's build setup.
- Validate input, escape output for its context, and enforce authorization on state-changing handlers. Cookie-authenticated browser actions also need CSRF/nonce protection; a nonce is not authorization. Frontend REST calls must send an `X-WP-Nonce` header (from `wp_create_nonce( 'wp_rest' )`, or through `@wordpress/api-fetch`), or WordPress treats them as logged out. Use WordPress APIs for queries, redirects, and HTTP requests.
- Keep queries bounded and cache expensive work. Avoid blocking remote calls on page loads; prefer background work and cached results. Anonymous responses are edge-cached: do not use PHP sessions or vary output by cookies without a cache-aware design. Version assets when their contents change, and version cached data when its format changes.
- Use a feature branch, not a deploy branch. Follow the customer's branch mapping; merging to an environment branch can deploy. Keep supporting docs, configuration, and tests with their feature; separate unrelated cleanup and independent vendor updates.
- Do not commit root `vendor/`, `node_modules/`, local overrides, or secrets. A component's runtime `vendor/` must ship if its deployed code needs it.
