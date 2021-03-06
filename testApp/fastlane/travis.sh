#!/bin/sh

# if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
if [ -z "$DEPLOY_MESSAGE" ]; then
#  fastlane test
#  exit $?
# Let's not load travis too much
    echo "just a test"
    exit 0;
fi

if [ -z "$DEPLOY_CHANNEL" ]; then
	echo "No deploy channel set"
	return 1
fi

export FASTLANE_PASSWORD=$(cat ./fastlane/apple_credentials.sh)

#just to test agents:
md5 testApp/Assets.xcassets/test_img.imageset/test_img.jpg
md5 testApp/Assets.xcassets/test_img.imageset/test_img@2x.jpg
md5 testApp/Assets.xcassets/test_img.imageset/test_img@3x.jpg

# Run agent
echo "Running agent"
cd fastlane/agent
npm install
cd ../..
./fastlane/agent/agent-cli.sh || { echo 'my_command failed' ; exit 1; }


#just to test agents:
md5 testApp/Assets.xcassets/test_img.imageset/test_img.jpg
md5 testApp/Assets.xcassets/test_img.imageset/test_img@2x.jpg
md5 testApp/Assets.xcassets/test_img.imageset/test_img@3x.jpg


# Prepare env vars
export MATCH_GIT_URL=$DEPLOY_MATCH_GIT_URL
export MATCH_PASSWORD=$DEPLOY_MATCH_PASSWORD
export MATCH_USERNAME=$DEPLOY_MATCH_USERNAME
export FASTLANE_USER=$DEPLOY_MATCH_USERNAME
export CRASHLYTICS_API_TOKEN=$DEPLOY_CRASHLYTICS_API_TOKEN
export CRASHLYTICS_BUILD_SECRET=$DEPLOY_CRASHLYTICS_BUILD_SECRET

# https://github.com/fastlane/fastlane/issues/6151#issuecomment-249993354
export FASTLANE_ITUNES_TRANSPORTER_USE_SHELL_SCRIPT=1


# Run fastlane
echo "Running fastlane"
fastlane $DEPLOY_CHANNEL
exit $?

