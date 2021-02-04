# VIP Go Skeleton

Welcome to VIP! This repo is a starting point for building your VIP Go site, including all the base folders to be built on.

## Guidebooks

We'd recommend starting with one of the following guidebooks. They include everything you need to know about launching and developing with VIP:

* [Launching with VIP](https://docs.wpvip.com/how-tos/launch-a-site-with-vip/)
* [Developing with VIP](https://wpvip.com/documentation/developing-with-vip/)

## Quick links to relevant documentation

To dig straight into our documentation and get up and running, try:

* [Understanding your VIP Go codebase](https://docs.wpvip.com/technical-references/vip-codebase/)
* [VIP Go local development](https://docs.wpvip.com/how-tos/set-up-a-vip-go-local-development-site/)

## Usage

All the following directories are required and must not be removed:

* `client-mu-plugins`: for always active, global plugins (similar to `mu-plugins`) — see [our documentation](https://docs.wpvip.com/technical-references/vip-codebase/client-mu-plugins-directory/) for more information.
* `images`: Store your site's favicons here, per [this documentation](https://docs.wpvip.com/technical-references/vip-codebase/images-directory/). All other public-facing images should be uploaded or [imported](https://docs.wpvip.com/how-tos/launch-a-site-with-vip/launch-with-vip-migrate-content/) to the WordPress dashboard or stored as part of your `/theme/` assets.
* `languages`: For `.po` and `.mo` translation files, which specify the translated strings for the site — [more details here](https://docs.wpvip.com/how-tos/upload-languages-to-the-language-directory/).
* `plugins`: Your site's plugins — [more details here](https://docs.wpvip.com/technical-references/vip-codebase/plugins-directory/).
* `private`: Provides access to files that are not directly web accessible, but can be accessed by your theme or plugin code — [more details here](https://docs.wpvip.com/technical-references/vip-codebase/private-directory/).
* `themes`: Themes to be made available to your sites – [more details here](https://docs.wpvip.com/technical-references/vip-codebase/themes-on-vip-go/). We recommend keeping the default theme available for [testing purposes](https://docs.wpvip.com/how-tos/prepare-for-site-launch/testing-your-site/).
* `vip-config`: For custom configuration changes and additional `sunrise.php` [details](https://docs.wpvip.com/technical-references/multisites/sunrise-php/). This folder’s `vip-config.php` file is used in place of `wp-config.php`. [More details here](https://docs.wpvip.com/technical-references/vip-codebase/vip-config-directory/).

These directories will also be available on production web servers. Any additional directories created in your GitHub repository that are not included in the above list will not be mounted onto your site, and so will not be web-accessible.

## Support

If you need help with anything, VIP's support team is [just a ticket away](https://wpvip.com/accessing-vip-support/ ).

## Your content here

Feel free to add to or replace this README.md content with content unique to your project, for example:

* Project-specific notes; like a list of VIP environments and branches,
* Workflow documentation; so everyone working in this repo can follow a defined process, or
* Instructions for testing new features.
