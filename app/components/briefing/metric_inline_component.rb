# typed: false
# frozen_string_literal: true

module Briefing
  class MetricInlineComponent < ViewComponent::Base
    Metric = Struct.new(:label, :value, :trend, keyword_init: true)

    def initialize(metrics:, show_labels: false)
      @metrics = metrics.map do |m|
        Metric.new(
          label: m[:label],
          value: m[:value],
          trend: m[:trend]
        )
      end
      @show_labels = show_labels
    end

    attr_reader :metrics, :show_labels

    def show_labels?
      @show_labels
    end

    def trend_indicator(trend)
      case trend
      when :up then '↑'
      when :down then '↓'
      else nil
      end
    end
  end
end
