require "log"
require "./request.cr"
require "./log_type.cr"
require "yaml"

Log.setup_from_env

# TODO: Write documentation for `IpBanner`
module IpBanner
  VERSION = "0.1.0"

  Log = ::Log.for("ipbanner")

  class IpBanner

    @config : YAML::Any

    def initialize
      @running = true
      @config = load_config()
    end

    def load_config
      # Loads the config from the /etc/ip_banner/ip_banner.yaml
      {% if flag? :test %}
        YAML.parse(File.read("#{__DIR__}/../spec/ip_banner.yaml"))
      {% else %}
        begin
          YAML.parse(File.read("/etc/ip_banner/ip_banner.yaml"))
        rescue File::NotFoundError
          STDERR.puts("COnfig file ot found in /etc/ip_banner/ip_banner.yaml")
          exit(80)
        end
      {% end %}
    end

    def forbidden_method?(method : String ,allowed_methods : Array(String)) : Bool
      # Returns a bool depending on if the request is allowed or not (true if not allowed and false otherwise)
      return true if method.size == 0
      return ! allowed_methods.includes?(method)
    end

    def forbidden_path?(path : String, allowed_paths : Array(String)) : Bool
      # Returns a bool depending on if the path is allowed or not (true if not allowed and false otherwise)
      return true if path.size == 0
      return ! allowed_paths.includes?(path)
    end

    def ban(ip : String)
      # Bans the IP via firewalld + logs it
      Process.new("firewall-cmd --add-rich-rule=\"rule family=ipv4 source address=#{ip} reject\"", shell: true)
      Log.info{"Banned IP #{ip}"}
    end

    def watch_file(file_path : String, log_type : LogType, allowed_paths : Array(String), allowed_methods : Array(String))
      # Watches a file, and bans suspicious request, depending on the given config
      file = File.open(file_path)
      while 1
        line = file.gets
        if line != nil
          request = Request.new(line.not_nil!, log_type)
          ban(request.ip) if forbidden_method?(request.method, allowed_methods) || forbidden_path?(request.path, allowed_paths)
        end
        Fiber.yield
      end
    end

    def start
      @config["files"].as_a.each do |config|
        spawn do
          watch_file(config["log_path"].as_s, LogNginx.new, config["allowed_paths"].as_a.map{|v| v.as_s}, config["allowed_methods"].as_a.map{|v| v.as_s})
        end
      end
    end
  end
end

# Config file in /etc/ip_banner/ip_banner.yaml

# Parse the command args
# Create instance
# Start