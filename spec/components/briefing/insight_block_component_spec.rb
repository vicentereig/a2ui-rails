# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::InsightBlockComponent, type: :component do
  let(:icon) { '🔋' }
  let(:headline) { 'Ready for intensity' }
  let(:narrative) { 'Body battery recharged to 91 overnight. HRV stable at 52ms.' }

  it 'renders the headline' do
    render_inline(described_class.new(icon: icon, headline: headline, narrative: narrative))

    expect(page).to have_text('Ready for intensity')
  end

  it 'renders the narrative text' do
    render_inline(described_class.new(icon: icon, headline: headline, narrative: narrative))

    expect(page).to have_text('Body battery recharged to 91 overnight')
    expect(page).to have_text('HRV stable at 52ms')
  end

  it 'supports different sentiment types' do
    render_inline(described_class.new(
      icon: '😴',
      headline: 'Solid sleep',
      narrative: 'You slept well.',
      sentiment: :positive
    ))

    expect(page).to have_css('[data-sentiment="positive"]')
  end

  it 'supports neutral sentiment' do
    render_inline(described_class.new(
      icon: '📊',
      headline: 'Training load',
      narrative: 'Maintaining balance.',
      sentiment: :neutral
    ))

    expect(page).to have_css('[data-sentiment="neutral"]')
  end

  it 'supports warning sentiment' do
    render_inline(described_class.new(
      icon: '⚠️',
      headline: 'High stress',
      narrative: 'Consider rest.',
      sentiment: :warning
    ))

    expect(page).to have_css('[data-sentiment="warning"]')
  end

  it 'applies component data attribute' do
    render_inline(described_class.new(icon: icon, headline: headline, narrative: narrative))

    expect(page).to have_css('[data-component="insight-block"]')
  end
end
