# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Base < ViewComponent::Base
      extend T::Sig

      sig { returns(String) }
      attr_reader :surface_id

      sig { returns(T::Hash[String, T.untyped]) }
      attr_reader :data

      sig { params(surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(surface_id:, data: {})
        @surface_id = surface_id
        @data = data
        super()
      end

      private

      sig { params(value: A2UI::Value).returns(String) }
      def resolve_value(value)
        case value
        when A2UI::LiteralValue
          value.value
        when A2UI::PathReference
          get_path(value.path).to_s
        else
          ''
        end
      end

      sig { params(path: String).returns(T.untyped) }
      def get_path(path)
        return @data if path.empty? || path == '/'

        parts = path.split('/').reject(&:empty?)
        parts.reduce(@data) { |obj, key| obj.is_a?(Hash) ? obj[key] : nil }
      end

      sig { params(path: String).returns(T::Hash[Symbol, String]) }
      def binding_attrs(path)
        {
          controller: 'a2ui-binding',
          'a2ui-binding-path-value': path,
          'a2ui-binding-surface-value': surface_id,
          action: 'input->a2ui-binding#update'
        }
      end

      sig { params(action: A2UI::Action).returns(T::Hash[Symbol, String]) }
      def action_attrs(action)
        context_json = action.context.map { |c| { c.key => c.path } }.to_json
        {
          controller: 'a2ui-action',
          'a2ui-action-name-value': action.name,
          'a2ui-action-context-value': context_json,
          'a2ui-action-surface-value': surface_id,
          action: 'click->a2ui-action#dispatch'
        }
      end
    end
  end
end
