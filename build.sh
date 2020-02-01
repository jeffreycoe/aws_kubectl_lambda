#!/bin/bash

function handle_exit_code() 
{
  EXIT_CODE=$1
  if [[ $EXIT_CODE -gt 0 ]]; then
    echo "ERROR: $2 RC: $EXIT_CODE"
    exit $EXIT_CODE
  fi
}

LAMBDA_FUNCTION_NAME=Kubectl
ZIP_FILENAME=KubectlLambdaFunction.zip
JQ_DOWNLOAD_URL=https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64

rm -r ./vendor

echo "Packaging AWS Lambda function $LAMBDA_FUNCTION_NAME"
bundle install --path ./vendor/bundle
handle_exit_code $? 'Failed to install Ruby Gems into ./vendor/bundle.'

mkdir -p ./vendor/bin
wget -O ./vendor/bin/jq $JQ_DOWNLOAD_URL
handle_exit_code $? 'Failed to install jq into ./vendor/bin'

chmod +x ./vendor/bin/jq
handle_exit_code $? 'Failed to add execute permissions to jq binary'

find . -iname '*.rb' -exec zip $ZIP_FILENAME {} \;
handle_exit_code $? 'Failed to add Ruby files to zip archive.'

zip -r $ZIP_FILENAME ./vendor
handle_exit_code $? 'Failed to add Ruby Gems to bundle.'

zip -r $ZIP_FILENAME ./resources
handle_exit_code $? 'Failed to add resources directory to bundle.'

echo "Generated $ZIP_FILENAME successfully!"
echo 'Build complete.'
