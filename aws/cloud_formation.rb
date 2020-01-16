require 'net/http'
require 'json'
require 'uri'

class AWS
  class CloudFormation    
    def initialize(response_url, stack_id, request_id, logical_resource_id)
      @response_url = response_url
      @stack_id = stack_id
      @request_id = request_id
      @logical_resource_id = logical_resource_id
    end
    
    def send_success
      status_code = http_put(provider_response('SUCCESS'))
      err_msg = "ERROR: Failed to send success message to CloudFormation pre-signed S3 URL. RC: #{status_code}"
      raise err_msg if status_code > 400
    end
    
    def send_failure
      status_code = http_put(provider_response('FAILED'))
      err_msg = "ERROR: Failed to send failure message to CloudFormation pre-signed S3 URL. RC: #{status_code}"
      raise err_msg if status_code > 400
    end
    
    def http_put(body = nil)
      uri = ::URI.parse(@response_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request = Net::HTTP::Put.new(uri)
      request.body = body.to_json
      request['Content-Type'] = 'application/json'

      response = http.request(request)
      
      response.code.to_i
    rescue => e
      puts "ERROR: Failed to send response to CloudFormation pre-signed S3 URL. Error Details: #{e}"
      raise e
    end
    
    def provider_response(status, reason = '')
      {
        Status: status,
        Reason: reason.to_s,
        PhysicalResourceId: @request_id,
        StackId: @stack_id,
        RequestId: @request_id,
        LogicalResourceId: @logical_resource_id,
        Data: {
            Result: 'OK'
        }
      }
    end
  end
end