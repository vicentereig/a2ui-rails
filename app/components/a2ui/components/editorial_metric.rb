# typed: strict
# frozen_string_literal: true

module A2UI
  module Components
    class EditorialMetric < Base
      extend T::Sig

      sig { params(component: A2UI::EditorialMetricComponent, surface_id: String, data: T::Hash[String, T.untyped]).void }
      def initialize(component:, surface_id:, data: {})
        @component = component
        super(surface_id: surface_id, data: data)
      end

      sig { returns(String) }
      def component_id
        @component.id
      end

      sig { returns(String) }
      def label
        @component.label
      end

      sig { returns(String) }
      def value
        @component.value
      end

      sig { returns(T.nilable(String)) }
      def trend
        @component.trend&.serialize
      end

      sig { returns(String) }
      def trend_icon
        case @component.trend
        when Briefing::TrendDirection::Up then '↑'
        when Briefing::TrendDirection::Down then '↓'
        when Briefing::TrendDirection::Stable then '→'
        else ''
        end
      end

      sig { returns(String) }
      def trend_class
        case @component.trend
        when Briefing::TrendDirection::Up then 'editorial-metric__trend--up'
        when Briefing::TrendDirection::Down then 'editorial-metric__trend--down'
        when Briefing::TrendDirection::Stable then 'editorial-metric__trend--stable'
        else ''
        end
      end

      sig { returns(T.nilable(String)) }
      def context
        @component.context
      end
    end
  end
end
