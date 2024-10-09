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
          STDERR.puts("Config file ot found at /etc/ip_banner/ip_banner.yaml")
          exit(80)
        end
      {% end %}
    end

    private def getLogType(config : YAML::Any) : LogType
      # Gets and returns a LogType instance for the given string, exits if error
      case config["log_type"].as_s
      when "custom"
        LogType.new(Regex.new(config["ip_regex"].as_s), Regex.new(config["method_regex"].as_s), Regex.new(config["path_regex"].as_s))
      when "nginx"
        LogType.new(/^(.*?) -/, /"([A-Z]{3,}) .*HTTP.*"/, /".*? (.*) HTTP.*"/)
      else
        STDERR.puts("The log type #{config["log_type"].as_s} does not exist")
        exit(81)
      end
    end

    def start
      # For each file specified in the config, creates a Watcher and starts it
      @config["files"].as_a.each do |config|
        spawn do
          allowed_paths = config["allowed_paths"].as_a.map{|v| v.as_s}
          allowed_methods = config["allowed_methods"].as_a.map{|v| v.as_s}
          begin
            log_type = getLogType(config)
          rescue
            STDERR.puts("Error while getting the LogType, unknown type : #{config["log_type"].as_s}")
            exit(81)
          end
          watcher = Watcher.new(config["log_path"].as_s, log_type, allowed_paths, allowed_methods)
          watcher.start
        end
      end
    end
  end
end