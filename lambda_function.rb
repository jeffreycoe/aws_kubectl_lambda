require 'json'

require_relative './aws/cli.rb'
require_relative './aws/eks/kubeconfig.rb'
require_relative './kubernetes/kubectl.rb'

def success(msg)
  { statusCode: 200, body: JSON.generate("#{msg}") }
end

def lambda_handler(event:, context:)
  if event['RequestType'] == 'Delete'
    msg = "#{event['RequestType'].to_s} event detected. "\
          "This method is not implemented. Skipping."

    return success(msg)
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

  success('EKS cluster config map updated successfully.')
end
