class AWS
  class EKS
    class Kubeconfig
      def initialize(config_file = "/tmp/kubeconfig")
        @config_file = config_file
        @aws_cli = AWS::CLI.new
      end
      
      def generate_kubeconfig(cluster_name)
        puts "Generating kubeconfig for EKS cluster #{cluster_name}..."

        @aws_cli.execute("eks update-kubeconfig --name \"#{cluster_name.chomp}\" --kubeconfig #{@config_file}")
      end
    end
  end
end