module IpBanner


  # A Request is an object which encapsulates the method, path and ip of a HTTP request
  class Request

    getter :ip, :path, :method

    # Creates a new `Request` instance from the given string and parses it using the given `LogFormat`
    def initialize(@request : String, @log_format : LogFormat)
      @method = ""
      @path = ""
      @ip = ""
      parse
    end

    private def scan_or_str(str : String, reg : Regex) : String
      # Returns the match of the given regex in the string or and empty string
      if str.scan(reg).size > 0
        str.scan(reg)[0][1]
      else
        ""
      end
    end

    private def parse
      # Gets the IP, method and path of a request depending on the log_format
        @ip = self.scan_or_str(@request, @log_format.ip_regex)
        @path = self.scan_or_str(@request, @log_format.path_regex)
        @method = self.scan_or_str(@request, @log_format.method_regex)
    end

  end
end