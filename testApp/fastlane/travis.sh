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


#just to test agents:
md5 testApp/Assets.xcassets/test_img.imageset/test_img.jpg

# Run agent
echo "Running agent"
cd fastlane/agent
npm install
cd ../..
./fastlane/agent/agent-cli.sh


#just to test agents:
md5 testApp/Assets.xcassets/test_img.imageset/test_img.jpg



# Run fastlane
echo "Running fastlane"
fastlane $DEPLOY_CHANNEL
exit $?

