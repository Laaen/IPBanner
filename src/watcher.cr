require "./request.cr"
require "./log_type.cr"

module IpBanner

    class Watcher
        # Reads the last line of the log file, and bans IPs depending on configuration given to it

        def initialize(@log_path : String, @log_type : LogType, @allowed_paths : Array(String), @allowed_methods : Array(String))
        end

        def start
            # Infinite loop, reads the last line of the @log_path file and bans its IP if applicable
            file = File.open(@log_path)
            while 1
              line = file.gets
              if line != nil
                request = Request.new(line.not_nil!, @log_type)
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