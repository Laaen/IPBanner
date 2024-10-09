require "./spec_helper"
require "../src/request.cr"
require "../src/log_type.cr"
require "file_utils"

describe IpBanner do

  describe "Test for different log formats"  do
  
    it "works for Nginx" do
      testLog("nginx")
    end
    
  end
end
