#!/bin/sh

# if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
if [ -z "$DEPLOY_MESSAGE"]; then
  fastlane test
  exit $?
fi

if [ -z "$DEPLOY_CHANNEL"]; then
	echo "No deploy channel set"
	return 1
fi

fastlane $DEPLOY_CHANNEL
exit $?

