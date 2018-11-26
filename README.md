# VIP Go Skeleton

The repo is a starting point for building your VIP Go site. It includes all the base folders that you need to build on.

To learn more, please see https://vip.wordpress.com/documentation/vip-go/understanding-your-vip-go-codebase/

## Usage

All the directories here are required and will be available on production web servers. Any extra directories will not be available in production.

## PHPCS

This repo contains a starting point for installing and using a _local_ version of [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer/) (PHPCS). To get started, you'll need [Composer](https://getcomposer.org/), then open a command line at this directory, and run:

```sh
composer install
```

This will:

 - install PHP_CodeSniffer
 - install the VIP Coding Standards
 - install the WordPress Coding Standards
 - install the PHPCompatibilityWP Standard
 - register the above standards with PHP_CodeSniffer

The [`.phpcs.xml.dist`](.phpcs.xml.dist) file contains a _suggested_ configuration, but you are free to amend this. We would strongly recommend:

 - keeping the `WordPress-VIP-Go` rule active
 - keeping the `PHPCompatibilityWP` rule active
 - setting the `prefixes` property for your theme and any plugins ([info](https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards/wiki/Customizable-sniff-properties#naming-conventions-prefix-everything-in-the-global-namespace))
 - setting the `text_domain` property for your theme and any plugins ([info](https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards/wiki/Customizable-sniff-properties#internationalization-setting-your-text-domain)) 
  
We would also recommend keeping the `WordPress-Extra` and `WordPress-Docs` rules active, though these are not required for VIP Go.

You can move or copy the `.phpcs.xml.dist` into the root of your theme and custom plugin directories, and adjust it for more granularity of configuration for theme and custom plugins.

To run PHPCS, navigate to the directory where the relevant `.phpcs.xml.dist` lives, and type:

```sh
vendor/bin/phpcs
```

See the [PHPCS documentation](https://github.com/squizlabs/PHP_CodeSniffer/wiki/Usage) (or run `phpcs -h`) for the available command line arguments.
