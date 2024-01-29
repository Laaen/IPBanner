import std/inotify
import posix
import strutils
import os
import yaml
import tables
import sequtils
import strformat
import times

proc getTime() : string =
    ## Returns the date + time YYYY-MM-DD HH:MM:SS
    result = now().format("yyyy-MM-dd HH:mm")

proc log (content : string) =
    ## Logs the content in the given file
    let file = open("/var/log/ip_banner.log", fmAppend)
    defer: file.close()
    writeLine(file, &"{getTime()} - {content}")

proc usage() =
    ## Tell how to use
    echo "./ip_banner FILE or DIR"

proc ban_ip(ip: string) : bool =
    ## Bans the ip via firewalld
    if execShellCmd(&"""firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="{ip}" reject'""") == 0:
        if execShellCmd("firewall-cmd --reload") == 0:
            log(&"IP banned : {ip}")

proc process_line(line: string, config : Table[string, seq[string]]) =
    ## Checks the line on multiple criterias (defined in the config.yaml file)
    ## This is where we ban IPs
    
    # Get the IP
    let ip = line.split(" ")[0]
    
    # Check if the method request is valid
    if "methods" in config.keys.toSeq:
       let req_method = line.split(" ")[5].strip(chars = {'"'})
       if not (req_method in config["methods"]):
            discard ban_ip(ip)
    
    # Check if the requested path is in the whitelist
    if "paths" in config.keys.toSeq:
        let path = line.split(" ")[6]
        if not (path in config["paths"]):
            discard ban_ip(ip)

proc start_watching(files: seq[string], config : Table[string, seq[string]]) =
    ## Starts watching for every file in the list for modification
    
    let inoty = inotify_init()

    # Table which associates filename : watchdescriptor
    var file_table : Table[cint, string]

    # Add the file to the watcher
    for file in files:
        file_table[inotify_add_watch(inoty, file, IN_MODIFY)] = file

    # Wait for modified events 
    var events = newSeq[byte](2048)
    while (let n = read(inoty, events[0].addr, 2048); n) > 0:
        for e in inotify_events(events[0].addr, n):
            # Get the file last line and process it
            let contenu = readFile(file_table[e.wd]).split("\n")
            if contenu.len > 1:
                # To prevent crashes due to malformed requests, we try
                try:
                    process_line(contenu[^1], config)
                except:
                    # Either we automatically ban, or we dismiss
                    echo contenu[^1]

# Check if at least one file is specified at launch
if commandLineParams().len == 0:
    echo "You need to provide at least one file or directory"
    usage()
    exitnow(1)

let args = commandLineParams()

# Load the configuration
var config : Table[string, seq[string]]  
let infos = readFile("/etc/ip_banner/config.yaml")
yaml.load(infos, config)

# Start the watchdog
start_watching(args, config)