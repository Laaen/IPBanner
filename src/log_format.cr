module IpBanner

    # Encapsulates the ip, method and path regexes used to extract data from a request line
    class LogFormat
        getter :ip_regex, :method_regex, :path_regex
        def initialize(@ip_regex : Regex, @method_regex : Regex, @path_regex : Regex)
        end
    end

end