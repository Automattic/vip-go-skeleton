# VIP Go CI Scripts

This document covers the steps to provide a build process for the VIP Go hosting platform on [WordPress.com VIP](https://vip.wordpress.com/). This build process should only be used for CSS, JS, and static resources, not for PHP (e.g. no `composer install`), or SVG files. The following example describes how a production site is developed and deployed using a flow which includes a build step:

1. Branch from `master` for a new feature
2. Develop cleanly with only your source code committed to your new branch (at this point you won't commit NPM installed modules, nor transpiled code, nor compressed images, etc)
3. Create a pull request, get it reviewed and approved, then merge to `master`
4. Your build steps run on the CI service
5. Our build script commits and pushes the build code to the `master-built` branch (and from there it is immediately deployed to your production site)

Note: The CI directory is not deployed to your VIP site, read more about VIP code structure in our [documentation about your VIP codebase](https://vip.wordpress.com/documentation/vip-go/understanding-your-vip-go-codebase/).

We have specific instructions below for Travis CI or Circle CI.

### [Circle CI](https://circleci.com/)

It's a good idea to read the [Circle CI getting started documentation](https://circleci.com/docs/1.0/getting-started/) (but don't add the suggested Circle CI config at this point).

The following instructions reference the `master` and `master-built` branch, but can be adapted for other branches, e.g. `develop` and `develop-built`.

0. Contact VIP to have us configure Circle CI for your repository, including adding a machine user to deploy the builds
1. Create a new PR, and add or adapt a config for Circle CI:
	* If you have no Circle CI config in your repository, copy [this config](https://raw.githubusercontent.com/Automattic/vip-go-build/master/.circleci/config.yml) to `.circleci/config.yml` in your repo; you will need to add the build command(s) you're using in the section under "@TODO: Configure build steps"
	* If you already have a Circle CI config, you'll need to:
	    1. Add the build command(s), referencing the section in our example config commented with "@TODO: Configure build steps"
			2. Add the two sets of two lines referenced by the `REQUIRED:` comments
2. Once you hear back from VIP that your repository is set up for Circle CI, trigger a build by merging a PR to `master`, this can be a non-significant change like a code comment… it should be built by Circle CI, committed to your `master-built` branch, and pushed up to GitHub (verify the branch now exists on GitHub and contains the changes you made)
3. Contact VIP again to have your environment changed to deploy from `master-built`
4. …that's it!

### [Travis CI](https://travis-ci.com)

It's a good idea to read the [Travis CI getting started documentation](https://docs.travis-ci.com/user/getting-started/), but don't add the Travis CI config at this point.

0. Visit https://travis-ci.com, authenticate with your GitHub account, and add your repository to Travis CI
1. Create or adapt a config for Travis CI:
	* If you have no Travis CI config in your repository, copy [this config](https://raw.githubusercontent.com/Automattic/vip-go-build/master/.travis.yml) to `.travis.yml` in your repo; you will need to add the build command(s) you're using in the section under "@TODO: Configure build steps"
	* If you already have a config, you'll need to:
		1. Add the build command(s), referencing the `before_script` section in our example config commented with "@TODO: Configure build steps"
		2. Add the two sets of two lines referenced by the `REQUIRED:` comments
2. Ensure you have a machine user, this is a regular GitHub user account which is used purely for scripted functions, e.g. used by Travis CI to commit and push the built code (GitHub call this user a ["machine user"](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users)):
  * If you have no dedicated "machine user" account, create a new GitHub account, named appropriately.
	* If you already have a machine user for your team, then use that account for the following steps.
3. Setup a key pair for your machine user
  * Use the commandline on your local machine to create a public private key pair ([documentation](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/))
  * Set the public portion of the key pair as a deploy key *with write permissions* on the GitHub repository ([documentation](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys))
  * Add the private key as a setting on your Travis repository (see "Adding a deploy key in repository settings on Travis CI" below)
4. Merge a PR to your `master` branch… it should be built by Travis CI, committed to your `master-built` branch, and pushed up to GitHub (verify the branch now exists on GitHub and contains the changes you made)
5. Contact VIP to have your environment changed to deploy from `master-built`
6. …that's it!

#### Adding a deploy key as a repository variable on Travis CI

Please read these instructions through before executing the steps.

Add the *public* portion of the key as a deploy key on your GitHub repository; [GitHub documentation on deploy keys](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys).

Set the *private* portion of the key as a repository variable in the Travis settings. You will need to replace newlines with \n and surround it with double quotes, e.g. "THIS\nIS\A\KEY\nABC\n123\n"; [Travis documentation on repository variables in settings](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings).

You *must* set the "Display value in build log" toggle for the repository variable to "off".

You *must* name the Travis setting that contains the key `BUILT_BRANCH_DEPLOY_KEY`.

## Credits

Inspiration (and some code) taken from [Human Made's VIP Go Builder](https://github.com/humanmade/vip-go-builder/), thank you!

