require "./spec_helper"
require "../src/request.cr"

describe IpBanner do

  
  it "detects forbidden methods" do

    sample_forbidden_methods = [
      %q{52.228.161.82 - - [27/Sep/2024:13:05:58 +0200] "MGLNDD_82.67.119.63_80" 400 157 "-" "-"},
      %q{80.82.77.202 - - [27/Sep/2024:11:31:50 +0200] "\x16\x03\x02\x01o\x01\x00\x01k\x03\x02RH\xC5\x1A#\xF7:N\xDF\xE2\xB4\x82/\xFF\x09T\x9F\xA7\xC4y\xB0h\xC6\x13\x8C\xA4\x1C=\x22\xE1\x1A\x98 \x84\xB4,\x85\xAFn\xE3Y\xBBbhl\xFF(=':\xA9\x82\xD9o\xC8\xA2\xD7\x93\x98\xB4\xEF\x80\xE5\xB9\x90\x00(\xC0" 400 157 "-" "-"},
      %q{179.43.133.162 - - [27/Sep/2024:20:06:06 +0200] "CONNECT cloudflare.com:443 HTTP/1.1" 400 157 "-" "-"},
      %q{172.233.24.243 - - [27/Sep/2024:02:55:02 +0200] "" 400 0 "-" "-"},
    ].map{|elt| IpBanner::Request.new(elt, IpBanner::LogType.parse("Nginx"))}
  
    sample_allowed_methods = [
      %q{95.214.55.138 - - [27/Sep/2024:01:00:37 +0200] "GET / HTTP/1.1" 301 169 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46"},
      %q{154.213.184.15 - - [27/Sep/2024:03:31:57 +0200] "POST /cgi-bin/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/bin/sh HTTP/1.1" 400 157 "-" "-"},
    ].map{|elt| IpBanner::Request.new(elt, IpBanner::LogType.parse("Nginx"))}

    banner = IpBanner::IpBanner.new(Hash(String, IpBanner::LogType).new, ["GET", "POST"], [] of String)

    sample_forbidden_methods.each do |request|
      banner.forbidden_method?(request.method).should be_true
    end

    sample_allowed_methods.each do |request|
      banner.forbidden_method?(request.method).should be_false
    end
  end

  it "detects forbidden paths" do

    sample_allowed_paths = [
      %q{95.214.55.138 - - [27/Sep/2024:01:00:37 +0200] "GET / HTTP/1.1" 301 169 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46"},
      %q{83.97.73.245 - - [27/Sep/2024:10:53:09 +0200] "GET /solr/admin/info/system?wt=json HTTP/1.1" 301 169 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36"},
    ].map{|elt| IpBanner::Request.new(elt, IpBanner::LogType.parse("Nginx"))}

    sample_forbidden_paths = [
      %q{64.62.197.108 - - [27/Sep/2024:07:11:35 +0200] "GET /geoserver/web/ HTTP/1.1" 301 169 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"},
      %q{52.228.161.82 - - [27/Sep/2024:13:05:58 +0200] "MGLNDD_82.67.119.63_80" 400 157 "-" "-"},
      %q{202.112.238.240 - - [27/Sep/2024:13:33:42 +0200] "\x16\x03\x01\x00\xEE\x01\x00\x00\xEA\x03\x03r\xA81\xC2\xC9\xAF\xA9\xB4\xCC\xED\xAA|\xF4\xDF\xC3\xDB\x1A\xE4\xECF\xDDH\x83\xEF\x10\x18\xA5\xB9\xD9\xF2[\x0F \xED\x88o\xE1R- \xD51`L\x04E\x0FA\xC8\xAE\x17\xED\x1B\xFB\xEE\xAF\xDD\x09\xE0\xE3(\x93\x12\x80 \x00&\xC0+\xC0/\xC0,\xC00\xCC\xA9\xCC\xA8\xC0\x09\xC0\x13\xC0" 400 157 "-" "-"},
      %q{154.213.184.15 - - [27/Sep/2024:14:44:51 +0200] "POST /cgi-bin/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/.%%%%32%%65/bin/sh HTTP/1.1" 400 157 "-" "-"},
      %q{179.43.133.162 - - [27/Sep/2024:20:06:06 +0200] "CONNECT cloudflare.com:443 HTTP/1.1" 400 157 "-" "-"},
    ].map{|elt| IpBanner::Request.new(elt, IpBanner::LogType.parse("Nginx"))}

    banner = IpBanner::IpBanner.new(Hash(String, IpBanner::LogType).new, [] of String, ["/solr/admin/info/system?wt=json", "/"])

    sample_forbidden_paths.each do |request|
      banner.forbidden_path?(request.path).should be_true
    end

    sample_allowed_paths.each do |request|
      banner.forbidden_path?(request.path).should be_false
    end

  end

  it "works for Nginx" do

    old_firewalld_bans = `sudo firewall-cmd --list-rich-rules`.scan(/address="(.*)"/).flatten

    spawn do
      banner = IpBanner::IpBanner.new({"#{__DIR__}/test.log" => IpBanner::LogType::Nginx}, ["GET", "POST"], ["/solr/admin/info/system?wt=json", "/"])
      banner.start
    end

    # Write to the watched file, we pause to let a chance to the watcher to get events
    File.read_lines("#{__DIR__}/example_file.log").each do |line|
      File.write("#{__DIR__}/test.log", "#{line}\n", mode: "a")
      sleep 0.001
    end

    
    # Wait some time, in real conditions it is not necessary as the main Fiber will loop indefinitely
    # But here we need to wait or the IPs to be banned via firewalld (takes some time)
    sleep 5

    # Check if ban was successful (we remove duplicate IPs from bannable requests)
    firewall_banned_ip_list = `sudo firewall-cmd --list-rich-rules`.scan(/address="(.*)"/).flatten
    firewall_banned_ip_list.size.should eq(32 + old_firewalld_bans.size)

    # Clean
    File.delete("#{__DIR__}/test.log")
    # Remove banned IPs
    firewall_banned_ip_list.each do |ip|
      `sudo firewall-cmd --remove-rich-rule 'rule family="ipv4" source #{ip} reject'`
    end

  end

end
