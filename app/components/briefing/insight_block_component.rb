# typed: false
# frozen_string_literal: true

module Briefing
  class InsightBlockComponent < ViewComponent::Base
    SENTIMENTS = %i[positive neutral warning].freeze

    def initialize(icon:, headline:, narrative:, sentiment: :neutral, metrics: [])
      @icon = icon
      @headline = headline
      @narrative = narrative
      @sentiment = SENTIMENTS.include?(sentiment) ? sentiment : :neutral
      @metrics = metrics
    end

    attr_reader :icon, :headline, :narrative, :sentiment, :metrics

    def metrics?
      @metrics.any?
    end
  end
end
