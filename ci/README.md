# VIP Go CI Scripts

## `deploy.sh` and `deploy-exclude.txt`

Scripts designed to facilitate building your Javascript and CSS
on either [Travis CI](https://travis-ci.com) or [Circle CI](https://circleci.com/).

See our documentation here: (NEEDS LINK, Ed)

Sample Circle CI config, put into `.circleci/config.yml`:

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
      - deploy:
          command: ci/deploy.sh
```

Sample Travis CI config, put into `.travis.yml`:

``` yml
language: php

sudo: false # Use modern Travis builds – http://docs.travis-ci.com/user/migrating-from-legacy/

# DEPLOY: This "ignore" directive travis from processing branches with a -built
# suffix, thus avoiding endless loops
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
after_script:
  - ci/deploy.sh
```

## Credits

Inspiration (and some code) taken from [Human Made's VIP Go Builder](https://github.com/humanmade/vip-go-builder/), thank you!
