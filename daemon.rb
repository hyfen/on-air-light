require 'daemons'

# Daemons.run_proc('detect_webcam.rb') do
#   puts "looping"
#   loop do
#     sleep(10)
#   end
# end

def custom_show_status(app)
  # Display the default status information
  app.default_show_status

  puts
  puts "PS information"
  system("ps -p #{app.pid.pid.to_s}")

  puts
  puts "Size of log files"
  system("du -hs /path/to/logs")
end

Daemons.run('detect_webcam.rb', { 
  show_status_callback: :custom_show_status 
})