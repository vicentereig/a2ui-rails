# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Briefing::BriefingComponent, type: :component do
  let(:name) { 'Vicente' }
  let(:date) { Date.new(2024, 12, 31) }

  it 'renders the greeting with name' do
    travel_to Time.zone.local(2024, 12, 31, 8, 0, 0) do
      render_inline(described_class.new(name: name, date: date))
      expect(page).to have_text('Good morning, Vicente')
    end
  end

  it 'renders the date' do
    render_inline(described_class.new(name: name, date: date))

    expect(page).to have_text('Tuesday, December 31')
  end

  it 'adjusts greeting based on time of day' do
    travel_to Time.zone.local(2024, 12, 31, 14, 0, 0) do
      render_inline(described_class.new(name: name, date: date))
      expect(page).to have_text('Good afternoon, Vicente')
    end

    travel_to Time.zone.local(2024, 12, 31, 19, 0, 0) do
      render_inline(described_class.new(name: name, date: date))
      expect(page).to have_text('Good evening, Vicente')
    end
  end

  it 'renders child content' do
    render_inline(described_class.new(name: name, date: date)) do
      '<div class="test-child">Child content</div>'.html_safe
    end

    expect(page).to have_css('.test-child')
    expect(page).to have_text('Child content')
  end

  it 'applies appropriate styling' do
    render_inline(described_class.new(name: name, date: date))

    expect(page).to have_css('[data-component="briefing"]')
  end
end
