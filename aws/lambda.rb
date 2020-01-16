class AWS
  class Lambda
    def success(msg)
      { statusCode: 200, body: JSON.generate("#{msg}") }
    end
  end
end