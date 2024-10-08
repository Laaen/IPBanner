require "log"
require "./request.cr"
require "./log_type.cr"
require "./watcher.cr"
require "yaml"

Log.setup_from_env

# TODO: Write documentation for `IpBanner`
module IpBanner
  VERSION = "0.1.0"

  Log = ::Log.for("ipbanner")

  LogType_hash = {"nginx" => LogNginx}

  class IpBanner

    @config : YAML::Any

    def initialize
      @running = true
      @config = load_config()
    end

    private def load_config
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

    def start
      # For each file specified in the config, creates a Watcher and starts it
      @config["files"].as_a.each do |config|
        spawn do
          allowed_paths = config["allowed_paths"].as_a.map{|v| v.as_s}
          allowed_methods = config["allowed_methods"].as_a.map{|v| v.as_s}
          log_type = LogType_hash[config["log_type"].as_s]
          watcher = Watcher.new(config["log_path"].as_s, log_type.new, allowed_paths, allowed_methods)
          watcher.start
        end
      end
    end
  end
end