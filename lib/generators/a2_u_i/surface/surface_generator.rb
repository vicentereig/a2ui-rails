# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/named_base'

module A2UI
  module Generators
    class SurfaceGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      desc 'Generate an A2UI surface with controller and views'

      class_option :skip_controller, type: :boolean, default: false,
                                     desc: 'Skip generating controller'
      class_option :skip_views, type: :boolean, default: false,
                                desc: 'Skip generating views'
      class_option :skip_routes, type: :boolean, default: false,
                                 desc: 'Skip adding routes'
      class_option :skip_specs, type: :boolean, default: false,
                                desc: 'Skip generating specs'

      def create_controller
        return if options[:skip_controller]

        template 'controller.rb.tt', "app/controllers/#{plural_file_name}_controller.rb"
      end

      def create_views
        return if options[:skip_views]

        template 'show.html.erb.tt', "app/views/#{plural_file_name}/show.html.erb"
      end

      def create_specs
        return if options[:skip_specs]

        template 'controller_spec.rb.tt', "spec/controllers/#{plural_file_name}_controller_spec.rb"
      end

      def add_routes
        return if options[:skip_routes]

        route_content = <<~RUBY
          resources :#{plural_file_name}, only: [:show] do
              member do
                post :generate
              end
            end
        RUBY

        route route_content.strip
      end

      def show_next_steps
        say ''
        say "✓ Surface '#{class_name}' created!", :green
        say ''
        say 'Files created:', :yellow
        say "  - app/controllers/#{plural_file_name}_controller.rb" unless options[:skip_controller]
        say "  - app/views/#{plural_file_name}/show.html.erb" unless options[:skip_views]
        say "  - spec/controllers/#{plural_file_name}_controller_spec.rb" unless options[:skip_specs]
        say ''
        say 'Next steps:', :yellow
        say "  1. Visit /#{plural_file_name}/:id to see your surface"
        say '  2. Customize the surface request in the controller'
        say '  3. Add business logic as needed'
        say ''
      end

      private

      def plural_file_name
        file_name.pluralize
      end

      def plural_class_name
        class_name.pluralize
      end
    end
  end
end
