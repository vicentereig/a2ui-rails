# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BriefingRecord, type: :model do
  describe 'validations' do
    it 'requires user_id' do
      record = BriefingRecord.new(date: Date.today, briefing_type: 'daily')
      expect(record).not_to be_valid
      expect(record.errors[:user_id]).to include("can't be blank")
    end

    it 'requires date' do
      record = BriefingRecord.new(user_id: 'user_123', briefing_type: 'daily')
      expect(record).not_to be_valid
      expect(record.errors[:date]).to include("can't be blank")
    end

    it 'requires valid briefing_type' do
      record = BriefingRecord.new(user_id: 'user_123', date: Date.today, briefing_type: 'invalid')
      expect(record).not_to be_valid
      expect(record.errors[:briefing_type]).to include('is not included in the list')
    end

    it 'enforces uniqueness of user_id, date, and briefing_type' do
      BriefingRecord.create!(user_id: 'user_123', date: Date.today, briefing_type: 'daily')

      duplicate = BriefingRecord.new(user_id: 'user_123', date: Date.today, briefing_type: 'daily')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    before do
      @daily = BriefingRecord.create!(user_id: 'user_123', date: Date.today, briefing_type: 'daily')
      @weekly = BriefingRecord.create!(user_id: 'user_123', date: Date.today.beginning_of_week, briefing_type: 'weekly')
      @other_user = BriefingRecord.create!(user_id: 'user_456', date: Date.today, briefing_type: 'daily')
    end

    it 'filters daily briefings' do
      expect(BriefingRecord.daily).to include(@daily)
      expect(BriefingRecord.daily).not_to include(@weekly)
    end

    it 'filters weekly briefings' do
      expect(BriefingRecord.weekly).to include(@weekly)
      expect(BriefingRecord.weekly).not_to include(@daily)
    end

    it 'filters by user' do
      expect(BriefingRecord.for_user('user_123')).to include(@daily, @weekly)
      expect(BriefingRecord.for_user('user_123')).not_to include(@other_user)
    end

    it 'filters by date' do
      expect(BriefingRecord.for_date(Date.today)).to include(@daily, @other_user)
    end
  end

  describe '.find_or_initialize_for' do
    it 'returns existing record if found' do
      existing = BriefingRecord.create!(user_id: 'user_123', date: Date.today, briefing_type: 'daily')

      found = BriefingRecord.find_or_initialize_for(user_id: 'user_123', date: Date.today)
      expect(found).to eq(existing)
      expect(found).to be_persisted
    end

    it 'initializes new record if not found' do
      record = BriefingRecord.find_or_initialize_for(user_id: 'user_new', date: Date.today)
      expect(record).not_to be_persisted
      expect(record.user_id).to eq('user_new')
      expect(record.briefing_type).to eq('daily')
    end
  end

  describe '#generated?' do
    it 'returns false when not generated' do
      record = BriefingRecord.new(user_id: 'user_123', date: Date.today, briefing_type: 'daily')
      expect(record.generated?).to be false
    end

    it 'returns true when generated' do
      record = BriefingRecord.new(
        user_id: 'user_123',
        date: Date.today,
        briefing_type: 'daily',
        output: { greeting: 'Hello' },
        generated_at: Time.current
      )
      expect(record.generated?).to be true
    end
  end

  describe '#total_tokens' do
    it 'sums input and output tokens' do
      record = BriefingRecord.new(input_tokens: 1000, output_tokens: 500)
      expect(record.total_tokens).to eq(1500)
    end

    it 'handles nil values' do
      record = BriefingRecord.new
      expect(record.total_tokens).to eq(0)
    end
  end

  describe '#week_start' do
    it 'returns monday of the week' do
      # Wednesday Jan 1, 2025 -> Monday Dec 30, 2024
      record = BriefingRecord.new(date: Date.new(2025, 1, 1))
      expect(record.week_start).to eq(Date.new(2024, 12, 30))
    end
  end

  describe 'hierarchical relationships' do
    it 'supports parent-child relationships' do
      weekly = BriefingRecord.create!(
        user_id: 'user_123',
        date: Date.today.beginning_of_week,
        briefing_type: 'weekly'
      )

      daily = BriefingRecord.create!(
        user_id: 'user_123',
        date: Date.today,
        briefing_type: 'daily',
        parent: weekly
      )

      expect(daily.parent).to eq(weekly)
      expect(weekly.children).to include(daily)
    end
  end
end
