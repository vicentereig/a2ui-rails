# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BriefingChannel, type: :channel do
  let(:user_id) { 'user_123' }

  describe '#subscribed' do
    it 'successfully subscribes with a user_id' do
      subscribe(user_id: user_id)

      expect(subscription).to be_confirmed
    end

    it 'streams from the user-specific briefing stream' do
      subscribe(user_id: user_id)

      expect(subscription).to have_stream_from("briefing:#{user_id}")
    end

    it 'rejects subscription without user_id' do
      subscribe(user_id: nil)

      expect(subscription).to be_rejected
    end

    it 'rejects subscription with empty user_id' do
      subscribe(user_id: '')

      expect(subscription).to be_rejected
    end
  end

  describe '#unsubscribed' do
    it 'stops all streams' do
      subscribe(user_id: user_id)
      expect(subscription).to have_stream_from("briefing:#{user_id}")

      subscription.unsubscribe_from_channel

      expect(subscription).not_to have_streams
    end
  end

  describe '#request_briefing' do
    before do
      subscribe(user_id: user_id)
    end

    it 'enqueues a briefing job' do
      travel_to Time.zone.local(2024, 12, 31) do
        expect {
          perform(:request_briefing, 'date' => '2024-12-31')
        }.to have_enqueued_job(GenerateBriefingJob)
          .with(user_id: user_id, date: '2024-12-31')
      end
    end

    it 'uses today as default date' do
      travel_to Time.zone.local(2024, 12, 31) do
        expect {
          perform(:request_briefing)
        }.to have_enqueued_job(GenerateBriefingJob)
          .with(user_id: user_id, date: '2024-12-31')
      end
    end

    it 'broadcasts a loading state' do
      expect {
        perform(:request_briefing, 'date' => '2024-12-31')
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(type: 'loading'))
    end
  end

  describe '.broadcast_insight' do
    it 'broadcasts an insight block to the user stream' do
      insight = Briefing::InsightBlock.new(
        icon: '😴',
        headline: 'Sleep Recovery',
        narrative: 'You slept well.',
        sentiment: Briefing::Sentiment::Positive
      )

      expect {
        described_class.broadcast_insight(user_id, insight)
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(
          type: 'insight',
          html: /Sleep Recovery/
        ))
    end
  end

  describe '.broadcast_suggestion' do
    it 'broadcasts a suggestion to the user stream' do
      suggestion = Briefing::Suggestion.new(
        title: 'Today',
        body: 'Push yourself.',
        suggestion_type: Briefing::SuggestionType::Intensity
      )

      expect {
        described_class.broadcast_suggestion(user_id, suggestion)
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(
          type: 'suggestion',
          html: /Push yourself/
        ))
    end
  end

  describe '.broadcast_complete' do
    it 'broadcasts a completion message' do
      expect {
        described_class.broadcast_complete(user_id)
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(type: 'complete'))
    end
  end

  describe '.broadcast_error' do
    it 'broadcasts an error message' do
      expect {
        described_class.broadcast_error(user_id, 'Something went wrong')
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(
          type: 'error',
          message: 'Something went wrong'
        ))
    end
  end
end
