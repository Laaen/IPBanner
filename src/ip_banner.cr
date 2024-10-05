require "log"

Log.setup_from_env

# TODO: Write documentation for `IpBanner`
module IpBanner
  VERSION = "0.1.0"

  Log = ::Log.for("ipbanner")

  class IpBanner
    def initialize(@files_paths : Array(String), @allowed_methods : Array(String), @allowed_paths : Array(String))
      @running = true
    end

    def forbidden_method?(request : String) : Bool
      # Returns a bool depending on if the request is allowed or not (true if not allowed and false otherwise)
      method = request.scan(/"([A-Z]{3,}) .*HTTP.*"/)
      return true if method.size == 0
      return ! @allowed_methods.includes?(method[0][1])
    end

    def forbidden_path?(request : String) : Bool
      # Returns a bool depending on if the path is allowed or not (true if not allowed and false otherwise)
      path = request.scan(/".*? (.*) HTTP.*"/)
      return true if path.size == 0
      return ! @allowed_paths.includes?(path[0][1])
    end

    def ban(request : String)
      # Bans the IP via firewalld + logs it and the incriminated request
      
      ip = request.split(" ").first
      Process.new("firewall-cmd --add-rich-rule=\"rule family=ipv4 source address=#{ip} reject\"", shell: true)

      # For tests purposes
      {% if flag? :test %}
        File.write("#{__DIR__.split("/")[0..-2].join("/")}/spec/output", "#{request}\n", mode: "a")
      {% end %}

      Log.info{"Banned IP #{ip} Request : #{request}"}

    end

    def watch_file(file_path : String)
      # Watches a file, and bans suspicious request
      file = File.open(file_path)
      while 1
        line = file.gets
        ban(line.not_nil!) if line != nil && (forbidden_method?(line.not_nil!) || forbidden_path?(line.not_nil!))
        Fiber.yield
      end
    end

    def start
      @files_paths.each do |f|
        spawn do
          watch_file(f)
        end
      end
    end
  end
end
