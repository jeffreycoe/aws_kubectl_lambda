# frozen_string_literal: true

require 'json'

module AWS
  class Lambda
    class Helper
      def success(msg)
        { statusCode: 200, body: JSON.generate(msg.to_s) }
      end
      
      def failure(msg)
        { statusCode: 500, body: JSON.generate("ERROR: #{msg}") } 
      end
    end
  end
end
