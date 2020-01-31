# Load all Ruby Gems stored in the local ./vendor/bundle directory
load_paths = Dir['./vendor/bundle/ruby/**/gems/**/lib']
$LOAD_PATH.unshift(*load_paths)

require 'aws_cloudformation_helper'

require_relative './aws/cli.rb'
require_relative './aws/eks/kubeconfig.rb'
require_relative './aws/lambda/helper.rb'
require_relative './kubernetes/kubectl.rb'

def create
  raise 'Config map file not found. Cannot perform create.' unless ::File.exist?(@config_map_file)

  @kubectl.apply(@config_map_file)
end

def delete
  @cfn_helper.logger.info('Delete event is not implemented for this resource. Skipping.')
end

def update
  raise 'Config map file not found. Cannot perform update.' unless ::File.exist?(@config_map_file)

  @kubectl.apply(@config_map_file)
end

def initialize_kubectl
  kubeconfig = AWS::EKS::Kubeconfig.new(@cfn_helper)
  @kubectl = Kubernetes::Kubectl.new(@cfn_helper)
  
  kubeconfig.generate_kubeconfig(@cluster_name)
end

def write_yaml_config_file
  @cfn_helper.logger.info('Writing k8s cluster config map file to /tmp/k8s-config-map.yml...')
  ::File.open(@config_map_file, 'w') { |file| file.write(@config_yaml) }  
end

def lambda_handler(event:, context:)
  # Initializes CloudFormation Helper library
  @cfn_helper = AWS::CloudFormation::Helper.new(self, event, context)
  
  # Add additional initialization code here
  @config_map_file = '/tmp/k8s-config-map.yml'
  @cluster_name = @cfn_helper.event.resource_properties['ClusterName']
  @config_yaml = @cfn_helper.event.resource_properties['ConfigMap']
  @cfn_helper.logger.info("Cluster Name: #{@cluster_name}")
  @cfn_helper.logger.info("Config YAML: \n#{@config_yaml}")

  initialize_kubectl
  write_yaml_config_file

  # Executes the event method
  @cfn_helper.event.execute
  @lambda_helper.success('Completed successfully.')
end
