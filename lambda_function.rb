require 'json'

require_relative './aws/cli.rb'
require_relative './aws/cloud_formation.rb'
require_relative './aws/lambda.rb'
require_relative './aws/eks/kubeconfig.rb'
require_relative './kubernetes/kubectl.rb'

def initialize_cfn_helper(event)
  @cfn ||= AWS::CloudFormation.new(event['ResponseURL'], event['StackId'], event['RequestId'], event['LogicalResourceId'])
  @cfn
end

def lambda_handler(event:, context:)
  lambda = AWS::Lambda.new
  initialize_cfn_helper(event)

  if event['RequestType'] == 'Delete'
    msg = "#{event['RequestType'].to_s} event detected. This method is not implemented. Skipping."

    @cfn.send_success
    return lambda.success(msg)
  end

  kubeconfig = AWS::EKS::Kubeconfig.new
  kubectl = Kubernetes::Kubectl.new

  config_map_file = '/tmp/aws-auth-cm.yml'
  cluster_name = event['ResourceProperties']['ClusterName']
  config_yaml = event['ResourceProperties']['ConfigMap']

  puts "Cluster Name: #{cluster_name}"
  puts "Config YAML: \n#{config_yaml}"

  kubeconfig.generate_kubeconfig(cluster_name)

  puts 'Writing k8s cluster config map file to /tmp/aws-auth-cm.yml...'
  ::File.open(config_map_file, 'w') { |file| file.write(config_yaml) }
  
  kubectl.apply(config_map_file)

  @cfn.send_success
  lambda.success('EKS cluster config map updated successfully.')
rescue => e
  # Send a failure message to the pre-signed S3 URL to notify cfn the resource failed
  @cfn.send_failure unless @cfn.nil?
  puts "CloudFormation helper is not initialized. Unable to send to failure response." if @cfn.nil?
  raise e
end
