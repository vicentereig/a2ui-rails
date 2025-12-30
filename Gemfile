# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.3'

# Core
gem 'dspy', '~> 0.34'
gem 'sorbet-runtime'

# Provider adapters - users choose one or more:
# gem 'dspy-openai'    # OpenAI, OpenRouter, Ollama
# gem 'dspy-anthropic' # Claude
# gem 'dspy-gemini'    # Gemini

# Rails
gem 'rails', '~> 8.0'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'propshaft'
gem 'puma'
gem 'sqlite3'

# View layer
gem 'view_component'
gem 'tailwindcss-rails'

group :development, :test do
  gem 'rspec-rails'
  gem 'vcr'
  gem 'webmock'
  gem 'debug'
  gem 'sorbet'
  gem 'tapioca'
  gem 'dspy-openai' # For testing
  gem 'dotenv-rails'
end

group :development do
  gem 'web-console'
end
