# frozen_string_literal: true

require 'securerandom'

module AWS
  class EKS
    class Kubeconfig
      attr_accessor :config_file

      def initialize(cfn_helper, config_file = nil)
        @cfn_helper = cfn_helper
        @config_file = config_file
        @aws_cli = AWS::CLI.new(@cfn_helper)
      end
      
      def generate_kubeconfig(cluster_name)
        raise "Cluster name was not specified." if cluster_name.to_s.empty?
        @config_file = "/tmp/kubeconfig-#{::SecureRandom.uuid}" if @config_file.nil?

        @cfn_helper.logger.info("Generating kubeconfig for EKS cluster #{cluster_name}...")
        @aws_cli.execute("eks update-kubeconfig --name \"#{cluster_name.chomp}\" --kubeconfig #{@config_file}")
        ENV['KUBECONFIG'] = @config_file

        @cfn_helper.logger.debug("KUBECONFIG Env Variable: #{ENV['KUBECONFIG']}")
        @cfn_helper.logger.info("Using kubeconfig file #{@config_file}")
        @config_file
      end
    end
  end
end
