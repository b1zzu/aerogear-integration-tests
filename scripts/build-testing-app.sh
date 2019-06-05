#!/usr/bin/env bash

set -e

if [ ! -d "./testing-app" ]; then
  cordova create testing-app
  cp fixtures/config.xml testing-app/
fi

cp fixtures/index.html testing-app/www/
cp fixtures/webpack.config.js testing-app/
cp fixtures/index.js testing-app/
cp fixtures/google-services.json testing-app/

cd testing-app

npm install --save \
  @aerogear/security@latest \
  @aerogear/app@latest \
  @aerogear/auth@latest \
  @aerogear/voyager-client@latest \
  @aerogear/push@latest \
  webpack \
  webpack-cli

cordova plugin add \
  @aerogear/cordova-plugin-aerogear-metrics \
  @aerogear/cordova-plugin-aerogear-push \
  @aerogear/cordova-plugin-aerogear-security \
  @aerogear/cordova-plugin-aerogear-sync 
cordova plugin add cordova-plugin-inappbrowser

npx webpack

if [ "$MOBILE_PLATFORM" = "ios" ]; then
  cordova platform add ios || true
  cordova build ios \
    --buildFlag="-UseModernBuildSystem=0" \
    --device \
    --codeSignIdentity="iPhone Developer" \
    --developmentTeam="$DEVELOPMENT_TEAM" \
    --packageType="development" \
    --buildFlag="-allowProvisioningUpdates"

  curl \
    -u "$BROWSERSTACK_USER:$BROWSERSTACK_KEY" \
    -X POST https://api-cloud.browserstack.com/app-automate/upload \
    -F "file=@$PWD/platforms/ios/build/device/HelloCordova.ipa" \
    >bs-app-url.txt
else
  cordova platform add android || true
  cordova build android

  curl \
    -u "$BROWSERSTACK_USER:$BROWSERSTACK_KEY" \
    -X POST https://api-cloud.browserstack.com/app-automate/upload \
    -F "file=@$PWD/platforms/android/app/build/outputs/apk/debug/app-debug.apk" \
    >bs-app-url.txt
fi
