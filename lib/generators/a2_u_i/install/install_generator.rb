# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'

module A2UI
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install A2UI into your Rails application'

      class_option :skip_routes, type: :boolean, default: false,
                                 desc: 'Skip adding routes'

      def create_initializer
        template 'initializer.rb.tt', 'config/initializers/a2ui.rb'
      end

      def add_routes
        return if options[:skip_routes]

        route "mount A2UI::Engine => '/a2ui'"
      end

      def create_application_css
        return if File.exist?('app/assets/stylesheets/a2ui.css')

        template 'a2ui.css.tt', 'app/assets/stylesheets/a2ui.css'
      end

      def show_post_install_message
        say ''
        say '✓ A2UI installed successfully!', :green
        say ''
        say 'Next steps:', :yellow
        say '  1. Configure your LM in config/initializers/a2ui.rb'
        say '  2. Run `rails generate a2_u_i:surface MyFeature` to create a surface'
        say '  3. Add <%= stylesheet_link_tag "a2ui" %> to your layout'
        say ''
      end
    end
  end
end
