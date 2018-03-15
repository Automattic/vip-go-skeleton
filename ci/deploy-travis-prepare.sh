#!/bin/bash -e
#
# Prepare to deploy your branch from Travis
#

# Keep the key out of the build log for security
set +x

# Nuke the existing SSH key
rm -fv ~/.ssh/id_rsa

# Create a new public private key pair (see "Generating a new
# SSH key" section, you don't need to add it to your agent)
# https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#generating-a-new-ssh-key
#
# Add the public portion of the key as a deploy key on
# your GitHub repository
# https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys
#
# Set the private portion of the key as a repository variable in the Travis settings
# You will need to replace newlines with \n and surrounded
# it with double quotes, e.g. "THIS\nIS\A\KEY\nABC\n123\n".
# https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings
echo -e ${BUILT_BRANCH_DEPLOY_KEY} > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Restore script echoing now we've done the private things
set -x

cp ${TRAVIS_BUILD_DIR}/ci/known_hosts ~/.ssh/known_hosts
