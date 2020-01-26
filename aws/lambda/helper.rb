require 'json'

module AWS
  class Lambda
    class Helper
      def success(msg)
        { statusCode: 200, body: JSON.generate("#{msg}") }
      end
      
      def failure(msg)
        { statusCode: 500, body: JSON.generate("ERROR: #{msg}") } 
      end
    end
  end
end