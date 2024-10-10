require "spec"
require "../src/ip_banner"
require "../src/request"
require "file_utils"
require "yaml"

def testLog(name : String)
    # Does the whole testing for a log type
 
    # Move the config file to the right folder
    FileUtils.cp("#{__DIR__}/config_files/#{name}.yaml", "#{__DIR__}/ip_banner.yaml")

    # Get the watched files list
    files_to_watch = YAML.parse(File.read("#{__DIR__}/ip_banner.yaml"))["files"]

    old_firewalld_bans = `firewall-cmd --list-rich-rules`.scan(/address="(.*)"/).flatten

    spawn do
      banner = IpBanner::IpBanner.new
      banner.start
    end

    # Write to the watched file, we pause to let a chance to the watcher to get events
    data = File.read_lines("#{__DIR__}/example_file.log")
    data = split_into(data, files_to_watch.size)
    files_to_watch.as_a.each_with_index do |file, idx|
      spawn do
        writeToLog(file["log_path"].as_s, data[idx])
      end
    end
    
    # Wait some time, in real conditions it is not necessary as the main Fiber will loop indefinitely
    # But here we need to wait or the IPs to be banned via firewalld (takes some time)
    sleep 5

    # Check if ban was successful (we remove duplicate IPs from bannable requests)
    firewall_banned_ip_list = `firewall-cmd --list-rich-rules`.scan(/address="(.*)"/).flatten
    firewall_banned_ip_list.size.should eq(32 + old_firewalld_bans.size)
    
    # Clean
    files_to_watch.as_a.each do |file|
      File.delete("#{__DIR__}/../#{file["log_path"].as_s}")
    end
    # Remove banned IPs
    firewall_banned_ip_list.each do |ip|
      `firewall-cmd --remove-rich-rule 'rule family="ipv4" source #{ip} reject'`
    end
    # Remove config file
    FileUtils.rm("#{__DIR__}/ip_banner.yaml")
end

def writeToLog(log_name : String, data : Array(String))
  # Writes 
  data.each do |line|
    File.write(log_name, "#{line}\n", mode: "a")
    sleep 0.001
  end
end

def split_into(data : Array(T), nb : Int) : Array(Array(T)) forall T
  # Splits an array into nb arrays
  result = Array.new(nb, Array(T).new)
  index = 0
  while index < data.size
    result.each_with_index do |arr, idx|
      if index < data.size
        result[idx] = result[idx].dup << data[index]
      end
      index += 1
    end
  end
  return result
end