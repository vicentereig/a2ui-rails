# typed: false
# frozen_string_literal: true

module Briefing
  class InsightBlockComponent < ViewComponent::Base
    SENTIMENTS = %i[positive neutral warning].freeze

    def initialize(icon:, headline:, narrative:, sentiment: :neutral)
      @icon = icon
      @headline = headline
      @narrative = narrative
      @sentiment = SENTIMENTS.include?(sentiment) ? sentiment : :neutral
    end

    attr_reader :icon, :headline, :narrative, :sentiment
  end
end
