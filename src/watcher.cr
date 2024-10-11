require "./request.cr"
require "./log_format.cr"

module IpBanner

    # Watcher instances loop to get the last line of a log file, and bans the IP of the corresponding request
    # depending on the given rules
    class Watcher

        # Instanciates a Watcher object
        # 
        # ```
        # log_format = LogFormat.new(...)
        # watcher = Watcher.new("./test.log", log_format, ["/", "/index.php"], ["GET", "POST"])
        # watcher.start
        # ```
        def initialize(@log_path : String, @log_format : LogFormat, @allowed_paths : Array(String), @allowed_methods : Array(String))
        end

        # Fiber looping to get the last line of `log_path`, the last line is converted to a `Request` object,
        # if its path or mathod is not in the allowed lists, its IP is banned via firewalld
        def start
            file = File.open(@log_path)
            while 1
              line = file.gets
              if line != nil
                request = Request.new(line.not_nil!, @log_format)
                ban(request.ip) if forbidden_method?(request.method) || forbidden_path?(request.path)
              end
              Fiber.yield
            end
        end

        private def forbidden_method?(method : String) : Bool
            # Returns a bool depending on if the request is allowed or not (true if not allowed and false otherwise)
            return true if method.size == 0
            return ! @allowed_methods.includes?(method)
        end
      
        private def forbidden_path?(path : String) : Bool
            # Returns a bool depending on if the path is allowed or not (true if not allowed and false otherwise)
            return true if path.size == 0
            return ! @allowed_paths.includes?(path)
        end
        
        private def ban(ip : String)
            # Bans the IP via firewalld + logs it
            Process.new("firewall-cmd --add-rich-rule=\"rule family=ipv4 source address=#{ip} reject\"", shell: true)
            Log.info{"Banned IP #{ip}"}
        end

    end
end