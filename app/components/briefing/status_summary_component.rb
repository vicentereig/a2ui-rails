# typed: false
# frozen_string_literal: true

module Briefing
  class StatusSummaryComponent < ViewComponent::Base
    SENTIMENTS = %i[positive neutral warning].freeze

    def initialize(headline:, summary:, sentiment: :neutral, metrics: [])
      @headline = headline
      @summary = summary
      @sentiment = SENTIMENTS.include?(sentiment) ? sentiment : :neutral
      @metrics = metrics
    end

    attr_reader :headline, :summary, :sentiment, :metrics

    def metrics?
      @metrics.any?
    end
  end
end
