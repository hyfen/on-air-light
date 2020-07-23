require 'rubygems'
require 'bundler/setup'
require 'pry'
require 'fosl/parser'

require_relative 'blinkstick'

VIDEO_DEVICE_FILENAMES = ["/dev/video", "AppleCamera"]
COLOR_ON = Color::RGB.new(50, 0, 0)
COLOR_OFF = Color::RGB.new(0, 50, 0)

module OnAir
  class Detector
    def initialize
      @parser = FOSL::Parser.new
    end
    
    def detect
      begin
        # FIXME: handle more than Zoom
        lsof_output = @parser.lsof("-c zoom")
      rescue RuntimeError => e
        handle_undetected
        return
      end

      # Get all the files that zoom has open and check to see if any of them
      # are a video device file
      open_files = lsof_output.values.first.files.map{|file| file[:name]}
      matches = VIDEO_DEVICE_FILENAMES.map do |video_filename|
        open_files.filter{|open_file| open_file.match(video_filename)}.any?
      end

      if matches.any?
        handle_detected
      else
        handle_undetected
      end
    end
    
    private
    
    def handle_detected
      puts "Camera on. Turning on light!"
      BlinkStick.find_all.each do | b |
        b.color = COLOR_ON
      end
    end

    def handle_undetected
      puts "No camera use detected"
      BlinkStick.find_all.each do | b |
        if COLOR_OFF
          b.color = COLOR_OFF
        else
          b.off
        end
      end
    end
  end
end

loop do
  d = OnAir::Detector.new
  d.detect
  sleep(5)
end