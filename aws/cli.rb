class AWS
  class CLI
    def aws_cli
      '/opt/awscli/aws'
    end
    
    def initialize
      ENV['PATH'] = "#{ENV['PATH']}\:#{::File.dirname(aws_cli)}"
    end
    
    def execute(cmd)
      puts "Executing AWS CLI command #{aws_cli} #{cmd}"
      `#{aws_cli} #{cmd}`   
    end

    def version
      `#{aws_cli} version`
    end
  end
end