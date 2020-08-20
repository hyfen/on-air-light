# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'pry'
require 'fosl/parser'

require_relative 'blinkstick'

VIDEO_DEVICE_FILENAMES = %w[/dev/video /dev/video0 AppleCamera].freeze
PROCESS_NAMES = %w[zoom firefox chrome].freeze
COLOR_ON = Color::RGB.new(50, 0, 0)
COLOR_OFF = Color::RGB.new(0, 50, 0)

module OnAir
  class Detector
    LSOF_ERROR_MESSAGE_WHEN_PROCESS_IS_NOT_FOUND = 'lsof exited with status 1'

    def initialize
      @parser = FOSL::Parser.new
    end

    def detect
      found_in_process = PROCESS_NAMES.detect do |process_name|
        detect_for_process process_name
      end

      if found_in_process
        handle_detected(found_in_process)
      else
        handle_undetected
      end
    end

    private

    def detect_for_process(process_name)
      open_files = files_opened_by_process(process_name)
      open_files.any? { |filename| VIDEO_DEVICE_FILENAMES.include? filename }
    end

    def files_opened_by_process(process_name)
      pid_data = @parser.lsof("-c #{process_name}").values
      file_hashes = pid_data.map(&:files).flatten
      found_files = file_hashes.map { |file_hash| file_hash[:name] }
    rescue RuntimeError => e
      pp e unless e.message == LSOF_ERROR_MESSAGE_WHEN_PROCESS_IS_NOT_FOUND
      found_files = []
    ensure
      return found_files
    end

    def handle_detected(process_name)
      puts "Camera being used by #{process_name}. Turning on light!"
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
