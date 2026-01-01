# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::MetricInlineComponent, type: :component do
  it 'renders a single metric' do
    render_inline(described_class.new(metrics: [{ label: 'Sleep', value: '7h 23m' }]))

    expect(page).to have_text('7h 23m')
  end

  it 'renders multiple metrics as pills' do
    render_inline(described_class.new(metrics: [
      { label: 'Duration', value: '45:12' },
      { label: 'Pace', value: '8:41/mi' },
      { label: 'HR', value: '148 bpm' }
    ]))

    expect(page).to have_text('45:12')
    expect(page).to have_text('8:41/mi')
    expect(page).to have_text('148 bpm')
    expect(page).to have_css('.metric-pill', count: 3)
  end

  it 'supports optional labels display' do
    render_inline(described_class.new(
      metrics: [{ label: 'Score', value: '79' }],
      show_labels: true
    ))

    expect(page).to have_text('Score')
    expect(page).to have_text('79')
  end

  it 'always shows labels in pills' do
    render_inline(described_class.new(metrics: [{ label: 'Score', value: '79' }]))

    expect(page).to have_text('Score')
    expect(page).to have_text('79')
  end

  it 'supports trend indicators' do
    render_inline(described_class.new(metrics: [
      { label: 'VO2 max', value: '48.5', trend: :up }
    ]))

    expect(page).to have_text('48.5')
    expect(page).to have_css('[data-trend="up"]')
  end

  it 'supports down trend' do
    render_inline(described_class.new(metrics: [
      { label: 'Weight', value: '175 lb', trend: :down }
    ]))

    expect(page).to have_css('[data-trend="down"]')
  end

  it 'applies component data attribute' do
    render_inline(described_class.new(metrics: [{ label: 'Steps', value: '8,432' }]))

    expect(page).to have_css('[data-component="metric-inline"]')
  end
end
