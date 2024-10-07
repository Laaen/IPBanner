require "log"
require "./request.cr"

Log.setup_from_env

# TODO: Write documentation for `IpBanner`
module IpBanner
  VERSION = "0.1.0"

  Log = ::Log.for("ipbanner")

  class IpBanner
    def initialize(@files_paths : Hash(String, LogType), @allowed_methods : Array(String), @allowed_paths : Array(String))
      # files_path Hash{log_path => LogType}
      @running = true
    end

    def forbidden_method?(method : String) : Bool
      # Returns a bool depending on if the request is allowed or not (true if not allowed and false otherwise)
      return true if method.size == 0
      return ! @allowed_methods.includes?(method)
    end

    def forbidden_path?(path : String) : Bool
      # Returns a bool depending on if the path is allowed or not (true if not allowed and false otherwise)
      return true if path.size == 0
      return ! @allowed_paths.includes?(path)
    end

    def ban(ip : String)
      # Bans the IP via firewalld + logs it
      
      Process.new("firewall-cmd --add-rich-rule=\"rule family=ipv4 source address=#{ip} reject\"", shell: true)
      Log.info{"Banned IP #{ip}"}

    end

    def watch_file(file_path : String, log_type : LogType)
      # Watches a file, and bans suspicious request
      file = File.open(file_path)
      while 1
        line = file.gets
        if line != nil
          request = Request.new(line.not_nil!, log_type)
          ban(request.ip) if forbidden_method?(request.method) || forbidden_path?(request.path)
        end
        Fiber.yield
      end
    end

    def start
      @files_paths.each do |path, log_type|
        spawn do
          watch_file(path, log_type)
        end
      end
    end
  end
end

# Parse the command args
# Create instance
# Start