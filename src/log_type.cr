module IpBanner

    abstract class LogType
        getter :ip_regex, :method_regex, :path_regex
        def initialize(@ip_regex : Regex, @method_regex : Regex, @path_regex : Regex)
        end
    end

    class LogNginx < LogType
        def initialize
            super(/^(.*?) -/, /"([A-Z]{3,}) .*HTTP.*"/, /".*? (.*) HTTP.*"/)
        end
    end


end