# frozen_string_literal: true

class Kubernetes
  class Kubectl
    def kubectl
      "#{@binary_path}/kubectl --kubeconfig \"#{@config_file}\""
    end
    
    def initialize(cfn_helper, config_file, binary_path = '/tmp/kubectl')
      @cfn_helper = cfn_helper
      @config_file = config_file
      @binary_path = binary_path

      unless ::File.exist?("#{@binary_path}/kubectl")
        @cfn_helper.logger.info("Copying kubectl binary to #{@binary_path}...")
        cmd = "mkdir -p #{@binary_path}; "\
              "cp -R -v /opt/kubectl/kubectl #{@binary_path}; "\
              "chmod +x #{@binary_path}/kubectl"

        exit_status = system(cmd)
        raise "Failed to copy kubectl binary to #{@binary_path}." unless exit_status

        ENV['KUBECTL_BINARY_PATH'] = binary_path
      end
    end

    def print_version
      `#{kubectl} version`
    end
    
    def apply(config_file)
      cmd = "#{kubectl} apply -f #{config_file}"
      @cfn_helper.logger.info("Executing #{cmd}")

      exit_status = system(cmd)
      raise 'Failed to execute kubectl apply command.' unless exit_status
      @cfn_helper.logger.info('kubectl apply executed successfully!')
    end
  end
end
