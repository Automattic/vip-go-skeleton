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

1. Create or adapt a config for Circle CI:
	* If you have no Circle CI config in your repository, copy the config below to `.circleci/config.yml`; you will need to add the build command(s) you're using in the section under "@TODO: Configure build steps"
	* If you already have a config, you'll need to tweak it to add the build command(s), referencing the section in our example config commented with "@TODO: Configure build steps" and then the section commented with "Run the deploy"
2. Ensure you have a machine user, this is a regular GitHub user account which is used purely for scripted functions, e.g. used by Circle CI to commit and push the built code (GitHub call this user a ["machine user"](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users)):
  * If you have no dedicated "machine user" account, create a new GitHub account, named appropriately.
	* If you already have a machine user for your team, then use that account for the following steps.
3. Grant your machine user access to the site GitHub repository
4. Log in to the Circle CI to create and add user keys for your machine user ([Circle CI docs on creating and adding a user key](https://circleci.com/docs/1.0/github-security-ssh-keys/#machine-user-keys)).
5. Merge a PR to your `master` branch… it should be built by Circle CI, committed to your `master-built` branch, and pushed up to GitHub (verify the branch now exists on GitHub and contains the changes you made)
6. Contact VIP to have your environment changed to deploy from `master-built`
7. …that's it!

#### Sample Circle CI config

See above for detailed instructions on using this sample config.

If you're not yet using Circle CI, drop the config below into your project and everything should just work. Put the following into `/.circleci/config.yml`:l

Important: Remember to configure your build steps below, see "@TODO: Configure build steps".

``` yml
version: 2
jobs:
  build:
    docker:
      # Pick a base image which matches the version of Node you need for
      # building from https://hub.docker.com/r/circleci/node/tags/
      #
      # Note: If using a different container, make sure it contains at least
      # git 2.6.0. (Use -stretch for circleci/node containers.)
      - image: circleci/node:6.11-stretch

    branches:
      # DEPLOY: Don't build from a branch with the `-built` suffix, to
      # prevent endless loops of deploy scripts.
      # Required: If you're amended an existing config, this is one
      # of the required lines
      ignore:
        - /^.*(?<!-built)$/
    steps:
      - checkout

      # @TODO: Configure build steps
      # - run: npm install
      # - run: npm run build
      #
      # These can also be specified with a name:
      # - run:
      #   name: Build the thing
      #   command: npm run build-thing

      # Run the deploy:
      - deploy:
          command: bash <(curl -D /tmp/headers-1.txt -s "https://raw.githubusercontent.com/Automattic/vip-go-build/master/deploy.sh")
```

### [Travis CI](https://travis-ci.com)

It's a good idea to read the [Travis CI getting started documentation](https://docs.travis-ci.com/user/getting-started/), but don't add the Travis CI config at this point.

1. Create or adapt a config for Travis CI:
	* If you have no Circle CI config in your repository, copy the config below to `.travis.yml`; you will need to add the build command(s) you're using in the `before_script` section under "@TODO: Configure build steps"
	* If you already have a config, you'll need to tweak it to add the build command(s), referencing the `before_script` section in our example config commented with "@TODO: Configure build steps" and also add the `after_script` section commented with "Run the deploy"
2. Ensure you have a machine user, this is a regular GitHub user account which is used purely for scripted functions, e.g. used by Circle CI to commit and push the built code (GitHub call this user a ["machine user"](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users)):
  * If you have no dedicated "machine user" account, create a new GitHub account, named appropriately.
	* If you already have a machine user for your team, then use that account for the following steps.
3. Setup a key pair for your machine user
  * Use the commandline on your local machine to create a public private key pair ([documentation](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/))
  * Set the key pair up as a deploy key with write permissions on the GitHub repository ([documentation](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys))
  * Add the private key as a setting on your Travis repository (see "Adding a deploy key in repository settings on Travis CI" below)
4. Merge a PR to your `master` branch… it should be built by Circle CI, committed to your `master-built` branch, and pushed up to GitHub (verify the branch now exists on GitHub and contains the changes you made)
5. Contact VIP to have your environment changed to deploy from `master-built`
6. …that's it!

#### Adding a deploy key as a repository variable on Travis CI

Please read these instructions through before executing the steps.

Add the *public* portion of the key as a deploy key on your GitHub repository; [GitHub documentation on deploy keys](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys).

Set the *private* portion of the key as a repository variable in the Travis settings. You will need to replace newlines with \n and surround it with double quotes, e.g. "THIS\nIS\A\KEY\nABC\n123\n"; [Travis documentation on repository variables in settings](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings).

You *must* name the Travis setting that contains the key `BUILT_BRANCH_DEPLOY_KEY`.

#### Sample Travis CI config

See above for detailed instructions on using this sample config.

If you're not yet using Travis CI, drop the config below into your project and everything should just work. Put the following into `/.travis.yml`:l

Important: Remember to configure your build steps below, see "@TODO: Configure build steps".

``` yml
language: php

# Use modern Travis builds for speed
# – http://docs.travis-ci.com/user/migrating-from-legacy/
sudo: false

# DEPLOY: This "ignore" directive travis from processing branches with a -built
# suffix, thus avoiding endless loops
# Required: If you're amended an existing config, this is one
# of the required lines
if: branch =~ ^.*(?<!-built)$


# @TODO: Configure build steps
# before_script:
# - run: npm install
# - run: npm run build

# Any tests you have will go in the `script` step, consult the
# Travis CI Documentation for details.

# DEPLOY: After everything else has run, run the deploy script.
# N.B. If you define no tests and/or no `script` directives, then
# each Travis build will appear to fail, although the deploy
# will succeed.
# If you want to only run the deploy script when tests pass, use
# `after_success` instead, you will need to add a `script`
# directive with some tests if you want to do this :)
# Required: If you're amended an existing config, the following
# two lines are required
after_script:
  - ci/deploy.sh
```

## Credits

Inspiration (and some code) taken from [Human Made's VIP Go Builder](https://github.com/humanmade/vip-go-builder/), thank you!
