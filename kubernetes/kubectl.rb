class Kubernetes
  class Kubectl
    def kubectl
      "#{@binary_path}/kubectl --kubeconfig \"#{@config_file}\""
    end
    
    def initialize(config_file = "/tmp/kubeconfig", binary_path = "/tmp/kubectl")
      @config_file = config_file
      @binary_path = binary_path

      unless ::File.exist?("#{@binary_path}/kubectl")
        puts "Copying kubectl binary to #{@binary_path}..."
        `mkdir -p #{@binary_path}; cp -R -v /opt/kubectl/kubectl #{@binary_path}; chmod +x #{@binary_path}/kubectl`
      end
    end
    
    def print_version
      `#{kubectl} version`
    end
    
    def apply(config_file)
      cmd = "#{kubectl} apply -f #{config_file}"
      puts "Executing #{cmd}"

      `#{cmd}`
    end
  end
end