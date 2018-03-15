#!/bin/bash -e
#
# Prepare to deploy your branch from Travis
#

# Keep the key out of the build log for security
set +x

# Nuke the existing SSH key
rm -fv ~/.ssh/id_rsa

# See ci/README.md for how to create and set this key
echo -e ${BUILT_BRANCH_DEPLOY_KEY} > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Restore script echoing now we've done the private things
set -x

cp ${TRAVIS_BUILD_DIR}/ci/known_hosts ~/.ssh/known_hosts
