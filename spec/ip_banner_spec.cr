require "./spec_helper"
require "../src/request.cr"
require "../src/log_type.cr"
require "file_utils"

describe IpBanner do

  describe "Test for different log formats"  do
  
    it "works for Nginx" do
      testLog("nginx")
    end

    it "works for custom log type" do
      # For now custom log type test is based on regex used by nginx + nginx log sample
      testLog("custom")
    end
  end

  it "can watch multiple files at the same time" do
    testLog("dual_files")
  end

end
