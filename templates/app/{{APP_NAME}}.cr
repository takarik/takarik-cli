# Load dependencies
require "takarik"
# Load logging
require "log"
# Load configuration
require "./config/config.cr"
# Load routes
require "./config/routes.cr"
# Load models
require "./models/*"

# Set log level to DEBUG for development
Log.for("takarik").level = Log::Severity::Debug

# Initialize the application
port = ENV["PORT"]?.try(&.to_i) || 3000
app = Takarik::Application.new(host: "0.0.0.0", port: port)

# Start the application server
app.run