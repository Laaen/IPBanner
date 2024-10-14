require "log"
require "./request.cr"
require "./log_format.cr"
require "./watcher.cr"
require "./error_codes.cr"
require "yaml"

Log.setup_from_env

# Watches log files from webservers, and bans IPs of request which try to do perform not allowed methods, or to access
# not allowed paths
module IpBanner
  VERSION = "0.5.0"
  Log = ::Log.for("ipbanner")

  
  class IpBanner

    @config : YAML::Any

    # Creates a new instance of IpBanner, then loads the config file at /etc/ip_banner/ip_banner.yaml
    def initialize
      @running = true
      @config = load_config()
      check_config()
    end

    private def load_config
      # Loads the config from the /etc/ip_banner/ip_banner.yaml
      {% if flag? :test %}
        YAML.parse(File.read("#{__DIR__}/../spec/ip_banner.yaml"))
      {% else %}
        begin
          YAML.parse(File.read("/etc/ip_banner/ip_banner.yaml"))
        rescue File::NotFoundError
          STDERR.puts("Config file not found at /etc/ip_banner/ip_banner.yaml")
          exit(ErrorCodes::ConfigFileNotFound.value)
        end
      {% end %}
    end

    private def check_config
      # Checks if the loaded config has the right structure
      begin
        # We try to access the required fields
        files = @config["files"].as_a.each do |file|
          file["log_path"].as_s
          file["allowed_paths"].as_a
          file["allowed_methods"].as_a
          file["log_format"].as_s
        end
      rescue
        STDERR.puts("Error : The config file has an incorrect structure ")
        exit(ErrorCodes::InvalidConfigFormat.value)
      end
    end

    private def getLogFormat(config : YAML::Any) : LogFormat
      # Gets and returns a LogFormat instance for the given string, exits if error
      case config["log_format"].as_s
      when "custom"
        LogFormat.new(Regex.new(config["ip_regex"].as_s), Regex.new(config["method_regex"].as_s), Regex.new(config["path_regex"].as_s))
      when "nginx"
        LogFormat.new(/^(.*?) -/, /"([A-Z]{3,}) .*HTTP.*"/, /".*? (.*) HTTP.*"/)
      else
        STDERR.puts("The log format #{config["log_format"].as_s} does not exist")
        exit(ErrorCodes::InvalidLogFormatGiven.value)
      end
    end

    # Creates a `Watcher` for every file specified in the config file at /etc/ip_banner/ip_banner.yaml 
    def start
      @config["files"].as_a.each do |config|
        spawn do
          allowed_paths = config["allowed_paths"].as_a.map{|v| v.as_s}
          allowed_methods = config["allowed_methods"].as_a.map{|v| v.as_s}
          begin
            log_format = getLogFormat(config)
          rescue
            STDERR.puts("Error while getting the log format, unknown format : #{config["log_format"].as_s}")
            exit(ErrorCodes::InvalidLogFormatGiven.value)
          end
          watcher = Watcher.new(config["log_path"].as_s, log_format, allowed_paths, allowed_methods)
          watcher.start
        end
      end
    end
  end
end

# Start
{% if !(flag? :test) %}
  ip_banner = IpBanner::IpBanner.new
  ip_banner.start()
  sleep
{% end %}