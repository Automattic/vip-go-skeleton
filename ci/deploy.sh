#!/bin/bash -e
#
# Deploy your branch on VIP Go.
#

# This script uses various Circle CI and Travis CI environment
# variables, Circle prefix their environment variables with
# `CIRCLE_` and Travis with `TRAVIS_`.
# Documentation:
# https://circleci.com/docs/1.0/environment-variables/
# https://docs.travis-ci.com/user/environment-variables/

set -ex

# The deploy suffix flexibility is mainly here to allow
# us to test Circle and Travis builds simultaneously on
# the https://github.com/Automattic/vip-go-skeleton/ repo.
DEPLOY_SUFFIX="${VIP_DEPLOY_SUFFIX:--built}"

BRANCH="${CIRCLE_BRANCH:-$TRAVIS_BRANCH}"

SRC_DIR="${TRAVIS_BUILD_DIR:-$PWD}"
BUILD_DIR="/tmp/vip-go-build"

if [[ $CIRCLECI ]]; then
	CIRCLE_REPO_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}";
fi
REPO_SLUG=${CIRCLE_REPO_SLUG:-$TRAVIS_REPO_SLUG}
REPO_SSH_URL="git@github.com:${REPO_SLUG}"
COMMIT_SHA=${CIRCLE_SHA1:-$TRAVIS_COMMIT}
DEPLOY_BRANCH="${BRANCH}${DEPLOY_SUFFIX}"
cd $SRC_DIR
COMMIT_AUTHOR_NAME="$( git log --format=%an -n 1 ${COMMIT_SHA} )"
COMMIT_AUTHOR_EMAIL="$( git log --format=%ae -n 1 ${COMMIT_SHA} )"
COMMIT_COMMITTER_NAME="$( git log --format=%cn -n 1 ${COMMIT_SHA} )"
COMMIT_COMMITTER_EMAIL="$( git log --format=%ce -n 1 ${COMMIT_SHA} )"


# Run some checks
# ---------------

if [[ -z "${BRANCH}" ]]; then
	echo "No branch specified!"
	exit 1
fi

if [[ -d "$BUILD_DIR" ]]; then
	echo "WARNING: ${BUILD_DIR} already exists. You may have accidentally cached this"
	echo "directory. This will cause issues with deploying."
	exit 1
fi

if [[ "${BRANCH}" == *${DEPLOY_SUFFIX} ]]; then
	echo "WARNING: Attempting to build from branch '${BRANCH}' to deploy '${DEPLOY_BRANCH}', seems like recursion so aborting."
	exit 1
fi

if [[ -n $TRAVIS ]] && [ $TRAVIS_PULL_REQUEST != 'false' ]; then
	echo "Aborting a build to '${DEPLOY_BRANCH}' from a pull request on '${BRANCH}', only build from merges directly to the branch"
	exit 0
fi

# Everything seems OK, getting the built repo sorted
# --------------------------------------------------

echo "Deploying ${BRANCH} to ${DEPLOY_BRANCH}"

# Making the directory we're going to sync the build into
git init "${BUILD_DIR}"
cd "${BUILD_DIR}"
git remote add origin "${REPO_SSH_URL}"
if [[ 0 = $(git ls-remote --heads "${REPO_SSH_URL}" "${DEPLOY_BRANCH}" | wc -l) ]]; then
	echo -e "\nCreating a ${DEPLOY_BRANCH} branch..."
	git checkout --quiet --orphan "${DEPLOY_BRANCH}"
else
	echo "Using existing ${DEPLOY_BRANCH} branch"
	git fetch origin "${DEPLOY_BRANCH}"
	git checkout --quiet "${DEPLOY_BRANCH}"
fi

# Copy the files over
# -------------------

if ! command -v 'rsync'; then
	sudo apt-get install -q -y rsync
fi

echo "Syncing files... quietly"
rsync --cvs-exclude -a "${SRC_DIR}/" "${BUILD_DIR}" --exclude-from "${SRC_DIR}/ci/deploy-exclude.txt"

# Make up the commit, commit, and push
# ------------------------------------

# Set Git committer
git config user.name "${COMMIT_COMMITTER_NAME}"
git config user.email "${COMMIT_COMMITTER_EMAIL}"

# Add changed files, delete deleted, etc, etc, you know the drill
git add -A .

if [ -z "$(git status --porcelain)" ]; then
	echo "No changes to deploy"
	exit 0
fi

# Commit it.
MESSAGE=$( printf 'Build changes from %s\n\n%s' "${COMMIT_SHA}" "${CIRCLE_BUILD_URL}" )
# Set the Author to the commit (expected to be a client dev) and the committer
# will be set to the default Git user for this CI system
git commit --author="${COMMIT_AUTHOR_NAME} <${COMMIT_AUTHOR_EMAIL}>" -m "${MESSAGE}"

# Push it (push it real good).
git push origin "${DEPLOY_BRANCH}"
