# typed: false
# frozen_string_literal: true

module Briefing
  # Editorial briefing component using What/So What/Now What framework
  # Renders a journalistic-style briefing with Catppuccin Latte styling
  class EditorialComponent < ViewComponent::Base
    TONES = %i[positive neutral warning].freeze

    def initialize(headline:, insight:, metrics: [], tone: :neutral)
      @headline = headline
      @insight = insight # Hash with :what, :so_what, :now_what keys
      @metrics = metrics
      @tone = TONES.include?(tone) ? tone : :neutral
    end

    attr_reader :headline, :insight, :metrics, :tone

    def metrics?
      @metrics.any?
    end

    # Render the full insight as editorial prose
    def insight_body
      parts = []
      parts << insight[:what] if insight[:what].present?
      parts << insight[:so_what] if insight[:so_what].present?
      parts.join(' ')
    end

    # The action/recommendation (Now What)
    def action_text
      insight[:now_what]
    end

    def trend_class(trend)
      case trend&.to_sym
      when :up then 'editorial-metric__trend--up'
      when :down then 'editorial-metric__trend--down'
      else 'editorial-metric__trend--stable'
      end
    end

    def trend_icon(trend)
      case trend&.to_sym
      when :up then '↑'
      when :down then '↓'
      else '→'
      end
    end
  end
end
