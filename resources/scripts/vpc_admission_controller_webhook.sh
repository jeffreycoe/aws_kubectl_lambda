#!/bin/bash

function handle_exit_code() 
{
  EXIT_CODE=$1
  if [[ $EXIT_CODE -gt 0 ]]; then
    echo "ERROR: $2 RC: $EXIT_CODE"
    exit $EXIT_CODE
  fi
}

echo 'Downloading scripts for VPC admission controller webhook deployment...'
echo "AWS Region: $AWS_REGION"
echo "Kubeconfig: $KUBECONFIG"

export PATH=$PATH:$KUBECTL_BINARY_PATH:$LAMBDA_TASK_ROOT/vendor/bin
export RANDFILE=/tmp/.random

curl -o ./webhook-create-signed-cert.sh https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/$AWS_REGION/vpc-admission-webhook/latest/webhook-create-signed-cert.sh
handle_exit_code $? 'Failed to download webhook-create-signed-cert.sh'

curl -o ./webhook-patch-ca-bundle.sh https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/$AWS_REGION/vpc-admission-webhook/latest/webhook-patch-ca-bundle.sh
handle_exit_code $? 'Failed to download webhook-patch-ca-bundle.sh'

curl -o ./vpc-admission-webhook-deployment.yaml https://amazon-eks.s3-us-west-2.amazonaws.com/manifests/$AWS_REGION/vpc-admission-webhook/latest/vpc-admission-webhook-deployment.yaml
handle_exit_code $? 'Failed to download vpc-admission-webhook-deployment.yaml'

echo 'Added execute permission to script files...'
chmod +x webhook-create-signed-cert.sh webhook-patch-ca-bundle.sh
handle_exit_code $? 'Failed to add execute permission to script files.'

echo 'Executing webhook-create-signed-cert.sh...'
./webhook-create-signed-cert.sh
handle_exit_code $? 'Error occurred while executing webhook-create-signed-cert script'

echo 'Verifying secret was created...'
kubectl get secret -n kube-system vpc-admission-webhook-certs
handle_exit_code $? 'Error occurred while verifying secret on cluster or secret does not exist.'

echo 'Generating VPC admission webhook deployment file...'
cat ./vpc-admission-webhook-deployment.yaml | ./webhook-patch-ca-bundle.sh > vpc-admission-webhook.yaml
handle_exit_code $? 'Error occurred while executing webhook-patch-ca-bundle script'
