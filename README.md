# ip_banner

Watches webservers files and bans undesired requests
Uses firewalld to block IPs

## Installation

Clone and build :  
(You need admin rights to perform tests as they use firewall-cmd)  
```
git clone https://github.com/Laaen/IPBanner.git
cd IPBanner/build
chmod u+x ./build.sh
./build.sh
```

Or, download in releases

## Usage

Create a config file at /etc/ip_banner/ip_banner.yaml  
Execute the binary : 
```
sudo ./ip_banner  
```
If you want to log banned IPs :  
```
sudo LOG_LEVEL=INFO ./ip_banner >> path_to_log_file
```

You can also create a service file to use with systemctl  

## Config file format

```
files:
  - log_path: "spec/test.log"                   => Path to the webserver log file
    allowed_paths:                              => List of allowed paths in requests
      - "/solr/admin/info/system?wt=json" 
      - "/"
    allowed_methods:                            => List of allowed methods in requests
      - "GET"
      - "POST"
    log_format: "custom"                        => Log format (possible formats are described below)
    ip_regex: "^(.*?) -"                        => Regex to retreive IP in request
    method_regex: "\"([A-Z]{3,}) .*HTTP.*\""    => Regex to retreive method in request
    path_regex: "\".*? (.*) HTTP.*\""           => Regex to retreive path in request
```

You can as many log path as you want  
ex :

```
files:
  - log_path: "spec/test_1.log"
    allowed_paths: 
      - "/solr/admin/info/system?wt=json"
      - "/"
    allowed_methods:
      - "GET"
      - "POST"
    log_format: "custom"
    ip_regex: "^(.*?) -"
    method_regex: "\"([A-Z]{3,}) .*HTTP.*\""
    path_regex: "\".*? (.*) HTTP.*\""

  - log_path: "spec/test_2.log"
    allowed_paths: 
      - "/solr/admin/info/system?wt=json"
      - "/"
    allowed_methods:
      - "GET"
      - "POST"
    log_format: "nginx"
```

## Log formats

Currently two log formats are supported :

### nginx 
You don't have to provide the regexes in the config file, they are already hardcoded  

```
ip_regex = ^(.*?) -  
method_regex = "([A-Z]{3,}) .*HTTP.*"  
path_regex = ".*? (.*) HTTP.*"  
```

### custom
You have to provide the regexes in the config file  

## Contributing

Contributions are welcome to add more log formats !  
You only have to modify the "getLogFormat" method in the IpBanner class  

1. Fork it (<https://github.com/your-github-user/ip_banner/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Laen](https://github.com/Laaen) - creator and maintainer
