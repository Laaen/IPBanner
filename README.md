# IPBanner

Small tool to dynamically ban IPs.

You need to use firewalld on your Linux (the IPs will be blocked by it)

It will check the last entry of the access.log everytime it is updated, and will check il the request complies with the given rules in the config.yaml file

/!\ I only tested it with nginx access.log file, it may need some modifications to correctly process files of others webservers /!\

## config.yaml
Simple yaml file, for now it works as a whitelist, you can add HTTP methods and paths.
If the request doesn't comply with those rules, its sender IP is blocked

## Setup
Put the ip_banner binary in /usr/bin/ip_banner
Put the service file in /etc/systemd/system/
Put the config file in /etc/ip_banner/config.yaml

Enjoy ! ;)

/!\ The location of the access.log file is hardcoded, you can change it in the source file, in the given bin, the path is /var/log/nginx/access.log /!\