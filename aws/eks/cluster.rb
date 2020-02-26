# frozen_string_literal: true

require 'json'

module AWS
  class EKS
    class Cluster
      def initialize(cfn_helper, cluster_name)
        @aws_cli = AWS::CLI.new(cfn_helper)
        @cfn_helper = cfn_helper
        @cluster_name = cluster_name.to_s.strip
      end

      def exist?
        json = ::JSON.parse(@aws_cli.execute('eks list-clusters', true))
        raise 'Unable to determine if cluster exists.' if json.nil?

        clusters = json['clusters']
        cluster_exists = false
        cluster_exists = true if clusters.include?(@cluster_name)
        @cfn_helper.logger.debug("exist?: clusters: #{clusters} cluster_exists: #{cluster_exists}")
        cluster_exists
      end

      def active?
        return false unless exist?

        json = ::JSON.parse(@aws_cli.execute("eks describe-cluster --name #{@cluster_name}", true))
        cluster_status = json['cluster']['status'].to_s.strip
        @cfn_helper.logger.debug("active?: cluster_status: #{cluster_status}")
        cluster_active = false
        cluster_active = true if cluster_status.eql?('ACTIVE')
        cluster_active
      end

      def disable_api_endpoint_public_access
        @cfn_helper.logger.info("Disabling EKS API endpoint public access for cluster #{@cluster_name}")
        cmd = "eks update-cluster-config "\
              "--name #{@cluster_name} "\
              '--resources-vpc-config endpointPublicAccess=false,endpointPrivateAccess=true'

        @aws_cli.execute(cmd)
      end

      def enable_cluster_logging
        @cfn_helper.logger.info("Enabling logging for EKS cluster #{@cluster_name}")
        log_opts = {
          "clusterLogging": [
            types: ["api","audit","authenticator","controllerManager","scheduler"],
            "enabled": true
          ]
        }

        cmd = "eks update-cluster-config "\
              "--name #{@cluster_name} "\
              "--logging \'#{log_opts.to_json}\'"

        @aws_cli.execute(cmd)
      end

      def wait_for_cluster_availability
        resource_properties = @cfn_helper.event.resource_properties
        cluster_name = resource_properties['ClusterName'].to_s.strip
        cluster = AWS::EKS::Cluster.new(@cfn_helper, cluster_name)
        timeout = 10
        timeout = resource_properties['Timeout'].to_i unless resource_properties['Timeout'].to_s.empty?
        start_time = ::Time.now
        wait_time = 0

        @cfn_helper.logger.info("Waiting for cluster #{cluster_name} to change to an active status")
        while (not wait_time >= (timeout * 60))
          break if cluster.active?

          wait_time = ::Time.now - start_time
          @cfn_helper.logger.debug("wait_for_cluster_availability: Cluster is not in an active state. Waiting.")
          sleep 10
        end

        err_msg = "Cluster #{@cluster_name} did not become active in the specified timeout period (#{timeout} minutes)"
        raise err_msg if wait_time >= (timeout * 60)

        @cfn_helper.logger.info("Cluster #{cluster_name} reported an active status!")
      end
    end
  end
end
