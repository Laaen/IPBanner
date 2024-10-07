module IpBanner

  class Request
    # A request, exposes its method, path, ip and body
    # It is parsed depending on the used webserver (given as the log_type parameter)

    getter :ip, :path, :method, :request

    def initialize(@request : String, @log_type : LogType)
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
      # Gets the IP, method and path of a request depending on the log_type
        @ip = self.scan_or_str(@request, @log_type.ip_regex)
        @path = self.scan_or_str(@request, @log_type.path_regex)
        @method = self.scan_or_str(@request, @log_type.method_regex)
    end

  end
end