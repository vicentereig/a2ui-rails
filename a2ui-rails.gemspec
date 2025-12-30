# frozen_string_literal: true

require_relative 'lib/a2ui/version'

Gem::Specification.new do |spec|
  spec.name = 'a2ui-rails'
  spec.version = A2UI::VERSION
  spec.authors = ['Vicente Reig']
  spec.email = ['vicente@vicente.services']

  spec.summary = 'A2UI for Rails - LLM-driven UI generation with Turbo Streams'
  spec.description = <<~DESC
    A Ruby port of Google's A2UI (Agent-to-User Interface) for Rails.
    Uses DSPy.rb to generate typed UI descriptions from natural language,
    rendered as ViewComponents via Turbo Streams.
  DESC
  spec.homepage = 'https://github.com/vicentereig/a2ui-rails'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/vicentereig/a2ui-rails'
  spec.metadata['changelog_uri'] = 'https://github.com/vicentereig/a2ui-rails/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(__dir__) do
    Dir['{lib}/**/*', 'LICENSE', 'README.md']
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'dspy', '~> 0.34'
  spec.add_dependency 'sorbet-runtime'
end
