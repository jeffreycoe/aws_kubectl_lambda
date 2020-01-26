module AWS
  class EKS
    class Kubeconfig
      def initialize(cfn_helper, config_file = "/tmp/kubeconfig")
        @cfn_helper = cfn_helper
        @config_file = config_file
        @aws_cli = AWS::CLI.new(@cfn_helper)
      end
      
      def generate_kubeconfig(cluster_name)
        raise "Cluster name was not specified." if cluster_name.to_s.empty?

        @cfn_helper.logger.info("Generating kubeconfig for EKS cluster #{cluster_name}...")
        @aws_cli.execute("eks update-kubeconfig --name \"#{cluster_name.chomp}\" --kubeconfig #{@config_file}")
      end
    end
  end
end