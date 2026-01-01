# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.3'

# Rails 8.1
gem 'rails', '~> 8.0'
gem 'puma'
gem 'sqlite3'
gem 'bootsnap', require: false

# Rails 8 defaults
gem 'solid_queue'
gem 'solid_cable'
gem 'mission_control-jobs'

# Asset pipeline
gem 'propshaft'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'tailwindcss-rails'

# View layer
gem 'view_component'

# A2UI core
gem 'dspy', '~> 0.34'
gem 'sorbet-runtime'

# Data access
gem 'duckdb'

group :development, :test do
  gem 'rspec-rails'
  gem 'vcr'
  gem 'webmock'
  gem 'debug'
  gem 'sorbet'
  gem 'tapioca'
  gem 'dspy-openai'
  gem 'dspy-anthropic'
  gem 'dotenv-rails'
  gem 'foreman'
  gem 'capybara'
end

group :development do
  gem 'web-console'
end
