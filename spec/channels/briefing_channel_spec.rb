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

  describe '.broadcast_status' do
    it 'broadcasts a status block to the user stream' do
      status = Briefing::StatusSummary.new(
        headline: 'Ready to perform',
        summary: 'Your recovery metrics look good.',
        sentiment: Briefing::Sentiment::Positive,
        metrics: []
      )

      expect {
        described_class.broadcast_status(user_id, status)
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(
          type: 'status',
          html: /Ready to perform/
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

  describe '.broadcast_token_usage' do
    it 'broadcasts token usage with model and counts' do
      token_usage = {
        model: 'anthropic/claude-haiku-4-5-20251001',
        input_tokens: 1500,
        output_tokens: 500
      }

      expect {
        described_class.broadcast_token_usage(user_id, token_usage)
      }.to have_broadcasted_to("briefing:#{user_id}")
        .with(hash_including(
          type: 'token_usage',
          model: 'anthropic/claude-haiku-4-5-20251001',
          input_tokens: 1500,
          output_tokens: 500,
          total_tokens: 2000
        ))
    end
  end
end
