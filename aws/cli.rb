module AWS
  class CLI
    def aws_cli
      '/opt/awscli/aws'
    end
    
    def initialize(cfn_helper)
      @cfn_helper = cfn_helper
      ENV['PATH'] = "#{ENV['PATH']}\:#{::File.dirname(aws_cli)}"
    end
    
    def execute(cmd)
      @cfn_helper.logger.info("Executing AWS CLI command #{aws_cli} #{cmd}")
      `#{aws_cli} #{cmd}`  
      @cfn_helper.logger.info("AWS CLI command executed successfully!")
    end

    def version
      `#{aws_cli} version`
    end
  end
end