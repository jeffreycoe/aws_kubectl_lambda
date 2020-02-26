# frozen_string_literal: true

require_relative './cluster.rb'

module AWS
  class EKS
    class Actions
      def initialize(cfn_helper, kubectl)
        @cfn_helper = cfn_helper
        @kubectl = kubectl

        @cluster_name = @cfn_helper.event.resource_properties['ClusterName'].to_s.strip
        @cluster = AWS::EKS::Cluster.new(@cfn_helper, cluster_name)
      end

      def deploy_vpc_admission_controller_webhook
        # Only execute the deployment during a create request
        return unless @cfn_helper.event.request_type.eql?('Create')
  
        @cfn_helper.logger.info('Attempting to deploy VPC admission controller webhook...')
        temp_script_path = '/tmp/kubectl/resources/scripts'
        script = "#{ENV['LAMBDA_TASK_ROOT']}/resources/scripts/vpc_admission_controller_webhook.sh"
        cmd = <<-CODE
          mkdir -p #{temp_script_path}
          cp #{script} #{temp_script_path}
          cd #{temp_script_path}
          chmod +x ./#{::File.basename(script)}

          ./#{::File.basename(script)}
        CODE
  
        exit_status = system(cmd)
        raise 'Failed to generate VPC admission controller webhook deployment file!' unless exit_status
  
        @cfn_helper.logger.info('Deploying VPC admission webhook deployment to EKS cluster')
        @kubectl.apply("#{temp_script_path}/vpc-admission-webhook.yaml")
      end

      def execute_action(action)
        case action
        when 'DeployVpcAdmissionControllerWebhook'
          deploy_vpc_admission_controller_webhook
        when 'WaitForClusterAvailability'
          @cluster.wait_for_cluster_availability
        when 'DisableApiEndpointPublicAccess'
          @cluster.disable_api_endpoint_public_access
        when 'EnableClusterLogging'
          @cluster.enable_cluster_logging
	  @cluster.wait_for_cluster_availability
        else
          err_msg = "Invalid action specified. Action: #{action}"
          @cfn_helper.logger.error(err_msg)
          raise err_msg
        end
      end
    end
  end
end
