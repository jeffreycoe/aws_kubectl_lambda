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

rm -r ./vendor

echo "Packaging AWS Lambda function $LAMBDA_FUNCTION_NAME"
bundle install --path ./vendor/bundle
handle_exit_code $? 'Failed to install Ruby Gems into ./vendor/bundle.'

find . -iname '*.rb' -exec zip $ZIP_FILENAME {} \;
handle_exit_code $? 'Failed to add Ruby files to zip archive.'

zip -r $ZIP_FILENAME ./vendor
handle_exit_code $? 'Failed to add Ruby Gems to bundle.'

echo "Generated $ZIP_FILENAME successfully!"
echo 'Build complete.'
