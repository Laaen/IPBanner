module IpBanner

    class LogType
        getter :ip_regex, :method_regex, :path_regex
        def initialize(@ip_regex : Regex, @method_regex : Regex, @path_regex : Regex)
        end
    end

end