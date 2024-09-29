# TODO: Write documentation for `IpBanner`
require "inotify"

module IpBanner
  VERSION = "0.1.0"

  class IpBanner
    def initialize(@files_paths : Array(String), @allowed_methods : Array(String), @allowed_paths : Array(String))
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

    def start
      watcher = Inotify::Watcher.new
      @files_paths.each do |f|
        watcher.watch f, Inotify::Event::Type::MODIFY.value
      end
      watcher.on_event do |event|
        puts event.path
      end

      sleep
    end

  end
end
