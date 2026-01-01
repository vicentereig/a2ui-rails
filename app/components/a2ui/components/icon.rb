# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class Icon < Base
      extend T::Sig

      sig { params(component: A2UI::IconComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def name
        @component.name
      end

      sig { returns(Integer) }
      def size
        @component.size
      end

      sig { returns(String) }
      def size_class
        case size
        when 0..16 then 'w-4 h-4'
        when 17..20 then 'w-5 h-5'
        when 21..24 then 'w-6 h-6'
        when 25..32 then 'w-8 h-8'
        else 'w-10 h-10'
        end
      end
    end
  end
end
