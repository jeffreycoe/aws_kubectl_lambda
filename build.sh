#!/bin/bash

function handle_exit_code() 
{
  EXIT_CODE=$1
  if [[ $EXIT_CODE -gt 0 ]]; then
    echo "ERROR: $2 RC: $EXIT_CODE"
    exit $EXIT_CODE
  fi
}

LAMBDA_FUNCTION_NAME=KubectlConfigMapApply
ZIP_FILENAME=KubectlConfigMapApply.zip

echo "Packaging AWS Lambda function $LAMBDA_FUNCTION_NAME"
bundle install --path ./vendor/bundle
handle_exit_code $? 'Failed to install Ruby Gems into ./vendor/bundle.'

find . -iname '*.rb' -exec zip $LAMBDA_FUNCTION_NAME.zip {} \;
handle_exit_code $? 'Failed to add Ruby files to zip archive.'

zip -r $LAMBDA_FUNCTION_NAME.zip ./vendor
handle_exit_code $? 'Failed to add Ruby Gems to bundle.'

echo "Generated $LAMBDA_FUNCTION_NAME.zip successfully!"
echo 'Build complete.'
