# Define application routes using the Takarik router DSL
require "../controllers/application_controller.cr"
require "../controllers/home_controller.cr"

Log.debug { "Defining routes..." }

Takarik::Router.define do
  root HomeController, :index
end

Log.debug { "Routes defined." }