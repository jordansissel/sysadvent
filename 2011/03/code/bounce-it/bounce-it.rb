require "rubygems"
require "sinatra"
require "logger"

logger = Logger.new(STDOUT)

# The main page
get "/" do
  haml :index
end

# Handle form submission
post "/" do
  # Log what we're doing.
  logger.info("Bouncing apache by request from #{request.ip}")

  # We should probably use Ruby's Open3 here, but let's keep
  # this simple for now.
  @output = %x(sudo apachectl graceful 2>&1)
  exitcode = $?.exitstatus
  @status = (exitcode == 0) ? "success" : "error"

  # Render it.
  haml :result
end
