require "./spec_helper"
require "../src/request.cr"
require "../src/log_type.cr"

describe IpBanner do
  
  it "works for Nginx" do

    old_firewalld_bans = `firewall-cmd --list-rich-rules`.scan(/address="(.*)"/).flatten

    spawn do
      banner = IpBanner::IpBanner.new
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
    firewall_banned_ip_list = `firewall-cmd --list-rich-rules`.scan(/address="(.*)"/).flatten
    firewall_banned_ip_list.size.should eq(32 + old_firewalld_bans.size)

    # Clean
    File.delete("#{__DIR__}/test.log")
    # Remove banned IPs
    firewall_banned_ip_list.each do |ip|
      `firewall-cmd --remove-rich-rule 'rule family="ipv4" source #{ip} reject'`
    end

  end

end
