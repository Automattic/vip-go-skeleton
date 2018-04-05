# VIP Go CI Scripts

This directory contains various scripts to handle a build process for the VIP Go hosting platform on [WordPress.com VIP](https://vip.wordpress.com/). The following example describes how a production site is developed and deployed using these scripts and a flow involving a build step:

1. Branch from `master` for a new feature
2. Develop with only your source code committed to your new branch
3. Create a pull request from your new branch onto `master`
4. VIP review and approve the pull request
5. You merge the pull request
6. The scripts in this directory are used to install/build/compress/transpile/etc, your Javascript and CSS dependencies
7. The resultant build is committed and pushed to the `master-built` branch, from there it is immediately deployed to your production site

The CI directory is not deployed to your VIP site, read more about VIP code structure in our [documentation about your VIP codebase](https://vip.wordpress.com/documentation/vip-go/understanding-your-vip-go-codebase/).

## Getting started – unlaunched site

For unlaunched sites, here are the steps to follow:

1. Get the build script set up for your `master` branch on the CI service of your choice, the script and documentation here support Circle CI and Travis CI
2. Ensure that the built code on `master-built` is as you expect
3. Contact VIP to have us switch your site to deploy from `master-built`
4. Deploy a test commit, and check the code is correct and that the site is working as expected

The process will be similar for launched sites, but we recommend testing on a non-production environment and branch first (i.e. not `master`).

## `deploy.sh` and `deploy-exclude.txt`

Scripts designed to facilitate building your Javascript and CSS
on either [Travis CI](https://travis-ci.com) or [Circle CI](https://circleci.com/). The techniques and resources described here can almost certainly be adapted for other CI platforms and tools.

See our documentation here: (NEEDS LINK, Ed)

### [Circle CI](https://circleci.com/)

To have this run on Circle CI, you will need to:

* Read the [Circle CI getting started documentation](https://circleci.com/docs/1.0/getting-started/) (don't add the suggested Circle CI config at this point)
* Add the Circle CI config to your repository (copy the config below) if you don't have one. If you already have a config, you'll need to tweak it to add the section commented with "Configure build steps" and then the section commented with "Run the deploy"
* Create a [GitHub machine user](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users) (if you don't already have one for your team)
* Grant your machine user access to the site GitHub repository
* Use the Circle CI UI to [create and add a user key](https://circleci.com/docs/1.0/github-security-ssh-keys/#machine-user-keys) for your machine user

#### Sample Circle CI config

If you're not yet using Circle CI, drop the config below into your project and everything should just work. Put the config in `/.circleci/config.yml`.

If you are already using Circle CI, look for the lines preceded by a `# Required:` comment and integrate them into your config. 

Important: Remember to configure your build steps below, see "Configure build steps:"

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

      # Configure build steps:
      # - run: npm install
      # - run: npm run build
      #
      # These can also be specified with a name:
      # - run:
      #   name: Build the thing
      #   command: npm run build-thing

      # Run the deploy:
      # Required: If you're amended an existing config, the following 
      # two lines are required
      - deploy:
          command: ci/deploy.sh
```

### [Travis CI](https://travis-ci.com)

* Read the [Travis CI getting started documentation](https://docs.travis-ci.com/user/getting-started/)
* Add a Travis CI config to your repository if you don't have one, or tweak the one you have
* Create a [GitHub machine user](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users) (if you don't already have one for your team)
* Use the commandline on your local machine to create a public private key pair ([documentation](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/))
* Set the key pair up as a deploy key with write permissions on the GitHub repository ([documentation](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys))
* Add the private key as a setting on your Travis repository (see "Creating and adding a deploy key" below)

#### Sample Travis CI config

If you are already using Travis CI, look for the lines preceded by a `# Required:` comment and integrate them into your config.

If you're not yet using Travis CI, drop the config below into your project and everything should just work. Put the following into `/.travis.yml`:


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


# DEPLOY: Example configure build steps:
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

#### Creating and adding a deploy key

Create a new public private key pair (see "Generating a new SSH key" section, you don't need to add it to your agent); [GitHub documentation on creating a new key pair](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#generating-a-new-ssh-key).

Add the public portion of the key as a deploy key on your GitHub repository; [GitHub documentation on deploy keys](https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys).

Set the private portion of the key as a repository variable in the Travis settings. You will need to replace newlines with \n and surround it with double quotes, e.g. "THIS\nIS\A\KEY\nABC\n123\n"; [Travis documentation on repository variables in settings](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings).

## Credits

Inspiration (and some code) taken from [Human Made's VIP Go Builder](https://github.com/humanmade/vip-go-builder/), thank you!
