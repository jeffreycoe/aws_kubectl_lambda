# frozen_string_literal: true

module AWS
  class CLI
    def aws_cli
      '/opt/awscli/aws'
    end
    
    def initialize(cfn_helper)
      @cfn_helper = cfn_helper
      ENV['PATH'] = "#{ENV['PATH']}\:#{::File.dirname(aws_cli)}"
    end
    
    def execute(cmd, return_stdout = false)
      exit_status = true
      @cfn_helper.logger.debug("Executing AWS CLI command #{aws_cli} #{cmd}")
      output = nil

      if return_stdout
        output = `#{aws_cli} #{cmd}`
        exit_status = $?.success?
        @cfn_helper.logger.debug("Exit status: #{exit_status} Output: #{output}")
      else
        exit_status = system("#{aws_cli} #{cmd}")
        @cfn_helper.logger.debug("Exit status: #{exit_status}")
      end

      raise 'Error occurred when executing AWS CLI command.' unless exit_status
      @cfn_helper.logger.debug('AWS CLI command executed successfully!')

      return output if return_stdout
    end

    def version
      `#{aws_cli} version`
    end
  end
end
