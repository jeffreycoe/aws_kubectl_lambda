# frozen_string_literal: true

# Load all Ruby Gems stored in the local ./vendor/bundle directory
load_paths = Dir['./vendor/bundle/ruby/**/gems/**/lib']
$LOAD_PATH.unshift(*load_paths)

require 'aws_cloudformation_helper'
require 'securerandom'

require_relative './aws/cli.rb'
require_relative './aws/eks/actions.rb'
require_relative './aws/eks/kubeconfig.rb'
require_relative './aws/lambda/helper.rb'
require_relative './kubernetes/kubectl.rb'

def create
  apply_configuration
end

def delete
  @cfn_helper.logger.info('Delete event is not implemented for this resource. Skipping.')
end

def update
  apply_configuration
end

def apply_configuration
  if @cfn_helper.event.resource_properties.include?('Action')
    actions = AWS::EKS::Actions.new(@cfn_helper, @kubectl)
    actions.execute_action(@cfn_helper.event.resource_properties['Action'].to_s.strip)
  else
    if @cfn_helper.event.resource_properties.include?('ConfigMapURL')
      @config_map_file = @cfn_helper.event.resource_properties['ConfigMapURL']
      @cfn_helper.logger.info("Using Config Map file from URL #{@config_map_file}")
    elsif @cfn_helper.event.resource_properties.include?('ConfigMap')
      @config_yaml = @cfn_helper.event.resource_properties['ConfigMap']
      @cfn_helper.logger.info("Config Map YAML: \n#{@config_yaml}")
      write_yaml_config_file
    end

    @kubectl.apply(@config_map_file)
  end
end

def initialize_kubectl
  kubeconfig = AWS::EKS::Kubeconfig.new(@cfn_helper)
  kubectl_config_file = kubeconfig.generate_kubeconfig(@cluster_name)

  @kubectl = Kubernetes::Kubectl.new(@cfn_helper, kubectl_config_file)
end

def write_yaml_config_file
  @cfn_helper.logger.info("Writing k8s cluster config map file to #{@config_map_file}...")
  ::File.open(@config_map_file, 'w') { |file| file.write(@config_yaml) }
  raise 'Config map file failed to write to filesystem.' unless ::File.exist?(@config_map_file)
end

def lambda_handler(event:, context:)
  # Initializes CloudFormation Helper library
  @cfn_helper = AWS::CloudFormation::Helper.new(self, event, context)

  # Add additional initialization code here
  @cfn_helper.logger.info("Begin execution for CloudFormation resource #{@cfn_helper.event.logical_resource_id}")
  @config_map_file = "/tmp/k8s-config-map-#{::SecureRandom.uuid}.yml"
  @cluster_name = @cfn_helper.event.resource_properties['ClusterName']
  @cfn_helper.logger.info("Cluster Name: #{@cluster_name}")
  lambda_helper = AWS::Lambda::Helper.new

  initialize_kubectl

  # Executes the event method
  @cfn_helper.event.execute
  @cfn_helper.logger.info("Execution completed for CloudFormation resource #{@cfn_helper.event.logical_resource_id}")
  lambda_helper.success('Completed successfully.')
end
