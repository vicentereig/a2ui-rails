# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::SuggestionComponent, type: :component do
  let(:title) { 'Today' }
  let(:body) { 'Good day for tempo or intervals. Your body can handle the load.' }

  it 'renders the title' do
    render_inline(described_class.new(title: title, body: body))

    expect(page).to have_text('Today')
  end

  it 'renders the suggestion content' do
    render_inline(described_class.new(title: title, body: body))

    expect(page).to have_text('Good day for tempo or intervals')
    expect(page).to have_text('Your body can handle the load')
  end

  it 'renders the lightbulb icon by default' do
    render_inline(described_class.new(title: title, body: body))

    expect(page).to have_text('💡')
  end

  it 'supports custom icons' do
    render_inline(described_class.new(title: title, body: body, icon: '🏃'))

    expect(page).to have_text('🏃')
    expect(page).not_to have_text('💡')
  end

  it 'supports different suggestion types' do
    render_inline(described_class.new(
      title: 'Recovery',
      body: 'Take it easy today.',
      suggestion_type: :recovery
    ))

    expect(page).to have_css('[data-suggestion-type="recovery"]')
  end

  it 'supports intensity suggestion type' do
    render_inline(described_class.new(
      title: 'Workout',
      body: 'Push yourself today.',
      suggestion_type: :intensity
    ))

    expect(page).to have_css('[data-suggestion-type="intensity"]')
  end

  it 'applies component data attribute' do
    render_inline(described_class.new(title: title, body: body))

    expect(page).to have_css('[data-component="suggestion"]')
  end
end
