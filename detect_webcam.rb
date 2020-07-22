require 'rubygems'
require 'bundler/setup'
require 'pry'
require 'fosl/parser'

require_relative 'blinkstick'

VIDEO_FILES = ["/dev/video", "AppleCamera"]

parser = FOSL::Parser.new
output = parser.lsof("-c zoom")

begin
  open_filenames = output.values.first.files.map{|x| x[:name]}
  matches = VIDEO_FILES.map do |video_filename|
    open_filenames.filter{|open_file| open_file.match(video_filename)}.any?
  end

  if matches.any?
    puts "Camera on. Turning on light!"
    BlinkStick.find_all.each { | b |
      b.color = Color::RGB.new(255, 0, 0)
    }
  end
rescue =>e 
  raise e
end

