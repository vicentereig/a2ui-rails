require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "active_storage/engine"

# Skipped frameworks (not used in this app):
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

module A2uiRails
  class Application < Rails::Application
    config.load_defaults 8.0

    # Autoload lib/a2ui
    config.autoload_lib(ignore: %w[assets tasks])

    # Use Solid Queue for background jobs
    config.active_job.queue_adapter = :solid_queue

    # ActionCable configuration
    config.action_cable.mount_path = "/cable"
  end
end
