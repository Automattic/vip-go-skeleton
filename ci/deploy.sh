#!/bin/bash -e
#
# Deploy your branch on VIP Go.
#

set -ex

DEPLOY_SUFFIX="-built"

BRANCH="${CIRCLE_BRANCH:-$TRAVIS_BRANCH}"
SRC_DIR="${TRAVIS_BUILD_DIR:-$PWD}"
BUILD_DIR="/tmp/vip-go-build"

if [[ -z "$BRANCH" ]]; then
	echo "No branch specified!"
	exit 1
fi

if [[ -d "$BUILD_DIR" ]]; then
	echo "WARNING: ${BUILD_DIR} already exists. You may have accidentally cached this"
	echo "directory. This will cause issues with deploying."
	exit 1
fi

cd $SRC_DIR

if [[ $CIRCLECI ]]; then
	CIRCLE_REPO_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}";
fi
REPO_SLUG=${CIRCLE_REPO_SLUG:-$TRAVIS_REPO_SLUG}
REPO_SSH_URL="git@github.com:${REPO_SLUG}"
COMMIT_SHA=${CIRCLE_SHA1:-$TRAVIS_COMMIT}
DEPLOY_BRANCH="${BRANCH}${DEPLOY_SUFFIX}"

# You can also exclude this on Travis with:
# if: branch =~ ^.*(?<!-built)$
# …or on CircleCI with:
# jobs:
#  build:
#    branches:
#      ignore:
#        - /^.*(?<!-built)$/
if [[ "$BRANCH" == *${DEPLOY_SUFFIX} ]]; then
	echo "WARNING: Attempting to build from branch '${BRANCH}' to deploy '${DEPLOY_BRANCH}', seems like recursion so aborting."
	exit 0
fi

echo "Deploying $BRANCH to $DEPLOY_BRANCH"

COMMIT_USER_NAME="$( git log --format=%ce -n 1 $COMMIT_SHA )"
COMMIT_USER_EMAIL="$( git log --format=%cn -n 1 $COMMIT_SHA )"
GIT_USER="${DEPLOY_GIT_USER:-$COMMIT_USER_NAME}"
GIT_EMAIL="${DEPLOY_GIT_EMAIL:-$COMMIT_USER_EMAIL}"

git clone "$REPO_SSH_URL" "$BUILD_DIR"
cd "$BUILD_DIR"
git fetch origin
# If the deploy branch doesn't already exist, create it from the empty root.
if ! git rev-parse --verify "remotes/origin/$DEPLOY_BRANCH" >/dev/null 2>&1; then
	echo -e "\nCreating $DEPLOY_BRANCH..."
	git checkout --orphan "${DEPLOY_BRANCH}"
else
	echo "Using existing $DEPLOY_BRANCH"
	git checkout "${DEPLOY_BRANCH}"
fi

# Ensure we're in the right dir
cd "$BUILD_DIR"

# Remove existing files
git rm -rfq .

# Sync built files
if ! command -v 'rsync'; then
	sudo apt-get install -q -y rsync
fi

echo "Syncing files... quietly"
rsync -a "$SRC_DIR/" "$BUILD_DIR" --exclude-from "$SRC_DIR/ci/deploy-exclude.txt"

# Add changed files
git add -A .

if [ -z "$(git status --porcelain)" ]; then
	echo "No changes to deploy"
	exit 0
fi

# Double-check our user/email config
if ! git config user.email; then
	git config user.name "$GIT_USER"
	git config user.email "$GIT_EMAIL"
fi

# Commit it.
MESSAGE=$( printf 'Build changes from %s\n\n%s' "${COMMIT}" "${CIRCLE_BUILD_URL}" )
git commit -m "$MESSAGE"

# Push it (real good).
git push origin "$DEPLOY_BRANCH"
