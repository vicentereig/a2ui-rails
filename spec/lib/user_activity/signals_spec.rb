# typed: false
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserActivity::Signals do
  describe UserActivity::Signals::ActivityType do
    it 'serializes activity types' do
      expect(UserActivity::Signals::ActivityType::PageLanding.serialize).to eq('page_landing')
      expect(UserActivity::Signals::ActivityType::SessionStart.serialize).to eq('session_start')
      expect(UserActivity::Signals::ActivityType::SessionEnd.serialize).to eq('session_end')
      expect(UserActivity::Signals::ActivityType::Interaction.serialize).to eq('interaction')
      expect(UserActivity::Signals::ActivityType::IdlePeriod.serialize).to eq('idle_period')
      expect(UserActivity::Signals::ActivityType::EngagementPeak.serialize).to eq('engagement_peak')
    end
  end

  describe UserActivity::Signals::EngagementLevel do
    it 'serializes engagement levels' do
      expect(UserActivity::Signals::EngagementLevel::Idle.serialize).to eq('idle')
      expect(UserActivity::Signals::EngagementLevel::Passive.serialize).to eq('passive')
      expect(UserActivity::Signals::EngagementLevel::Active.serialize).to eq('active')
      expect(UserActivity::Signals::EngagementLevel::HighlyEngaged.serialize).to eq('highly_engaged')
    end
  end

  describe UserActivity::Signals::ActivitySignal do
    it 'creates a complete signal' do
      signal = UserActivity::Signals::ActivitySignal.new(
        id: 'page_landing_abc123_1735678800',
        activity_type: UserActivity::Signals::ActivityType::PageLanding,
        priority: UserActivity::Signals::SignalPriority::Medium,
        title: 'Page View',
        summary: 'User visited /dashboard.',
        timestamp: Time.new(2025, 12, 31, 8, 0, 0),
        session_id: 'abc123',
        metadata: { 'page_path' => '/dashboard' }
      )

      expect(signal.id).to eq('page_landing_abc123_1735678800')
      expect(signal.activity_type).to eq(UserActivity::Signals::ActivityType::PageLanding)
      expect(signal.session_id).to eq('abc123')
      expect(signal.metadata['page_path']).to eq('/dashboard')
    end
  end

  describe UserActivity::Signals::SessionMetrics do
    it 'creates session metrics with defaults' do
      now = Time.now
      metrics = UserActivity::Signals::SessionMetrics.new(
        session_id: 'test_session',
        started_at: now,
        last_interaction_at: now
      )

      expect(metrics.session_id).to eq('test_session')
      expect(metrics.interaction_count).to eq(0)
      expect(metrics.page_views).to eq(0)
      expect(metrics.scroll_depth_max).to eq(0.0)
      expect(metrics.engagement_level).to eq(UserActivity::Signals::EngagementLevel::Idle)
    end
  end

  describe UserActivity::Signals::ActivityEvaluator do
    let(:evaluator) { UserActivity::Signals::ActivityEvaluator.new }
    let(:session_id) { 'test_session_123' }

    describe '#record_page_landing' do
      it 'creates session start signal for new session' do
        signals = evaluator.record_page_landing(
          session_id: session_id,
          page_path: '/dashboard',
          timestamp: Time.now
        )

        expect(signals.length).to eq(2) # session_start + page_landing
        session_start = signals.find { |s| s.activity_type == UserActivity::Signals::ActivityType::SessionStart }
        expect(session_start).to be_present
        expect(session_start.title).to eq('New Session')
      end

      it 'creates page landing signal' do
        signals = evaluator.record_page_landing(
          session_id: session_id,
          page_path: '/dashboard',
          timestamp: Time.now
        )

        page_landing = signals.find { |s| s.activity_type == UserActivity::Signals::ActivityType::PageLanding }
        expect(page_landing).to be_present
        expect(page_landing.metadata['page_path']).to eq('/dashboard')
      end

      it 'increments page views on subsequent landings' do
        evaluator.record_page_landing(session_id: session_id, page_path: '/home')
        evaluator.record_page_landing(session_id: session_id, page_path: '/about')
        signals = evaluator.record_page_landing(session_id: session_id, page_path: '/contact')

        page_landing = signals.find { |s| s.activity_type == UserActivity::Signals::ActivityType::PageLanding }
        expect(page_landing.metadata['page_views']).to eq(3)
      end
    end

    describe '#record_interaction' do
      before do
        evaluator.record_page_landing(session_id: session_id, page_path: '/dashboard')
      end

      it 'tracks interaction count' do
        5.times do |i|
          evaluator.record_interaction(
            session_id: session_id,
            interaction_type: 'click',
            target: "button_#{i}"
          )
        end

        metrics = evaluator.session_metrics(session_id: session_id)
        expect(metrics.interaction_count).to eq(5)
      end

      it 'detects engagement level increase to passive' do
        signals = []
        4.times do |i|
          signals += evaluator.record_interaction(
            session_id: session_id,
            interaction_type: 'click',
            target: "button_#{i}"
          )
        end

        engagement_signal = signals.find { |s| s.activity_type == UserActivity::Signals::ActivityType::EngagementPeak }
        expect(engagement_signal).to be_present
        expect(engagement_signal.metadata['new_level']).to eq('passive')
      end

      it 'detects engagement level increase to active' do
        signals = []
        10.times do |i|
          signals += evaluator.record_interaction(
            session_id: session_id,
            interaction_type: 'click',
            target: "button_#{i}"
          )
        end

        engagement_signals = signals.select { |s| s.activity_type == UserActivity::Signals::ActivityType::EngagementPeak }
        active_signal = engagement_signals.find { |s| s.metadata['new_level'] == 'active' }
        expect(active_signal).to be_present
      end

      it 'detects idle recovery' do
        idle_time = Time.now - 150 # 2.5 minutes ago
        evaluator.record_interaction(
          session_id: session_id,
          interaction_type: 'click',
          target: 'button',
          timestamp: idle_time
        )

        signals = evaluator.record_interaction(
          session_id: session_id,
          interaction_type: 'click',
          target: 'button2',
          timestamp: Time.now
        )

        recovery_signal = signals.find { |s| s.title == 'User Returned' }
        expect(recovery_signal).to be_present
      end
    end

    describe '#record_scroll_depth' do
      before do
        evaluator.record_page_landing(session_id: session_id, page_path: '/long-article')
      end

      it 'signals at 25% milestone' do
        signals = evaluator.record_scroll_depth(
          session_id: session_id,
          depth: 0.30
        )

        expect(signals.length).to eq(1)
        expect(signals.first.title).to eq('Scroll: 25%')
      end

      it 'signals at 50% milestone' do
        evaluator.record_scroll_depth(session_id: session_id, depth: 0.30)
        signals = evaluator.record_scroll_depth(session_id: session_id, depth: 0.55)

        expect(signals.length).to eq(1)
        expect(signals.first.title).to eq('Scroll: 50%')
      end

      it 'does not signal for decreasing depth' do
        evaluator.record_scroll_depth(session_id: session_id, depth: 0.50)
        signals = evaluator.record_scroll_depth(session_id: session_id, depth: 0.30)

        expect(signals).to be_empty
      end
    end

    describe '#detect_idle_sessions' do
      it 'detects idle sessions after threshold' do
        past_time = Time.now - 180 # 3 minutes ago
        evaluator.record_page_landing(session_id: session_id, page_path: '/page', timestamp: past_time)

        # Make some interactions to raise engagement level
        5.times do |i|
          evaluator.record_interaction(
            session_id: session_id,
            interaction_type: 'click',
            target: "button_#{i}",
            timestamp: past_time
          )
        end

        signals = evaluator.detect_idle_sessions(current_time: Time.now)

        expect(signals.length).to eq(1)
        expect(signals.first.activity_type).to eq(UserActivity::Signals::ActivityType::IdlePeriod)
        expect(signals.first.title).to eq('User Idle')
      end

      it 'does not signal for already idle sessions' do
        past_time = Time.now - 180
        evaluator.record_page_landing(session_id: session_id, page_path: '/page', timestamp: past_time)

        # First detection
        evaluator.detect_idle_sessions(current_time: Time.now)

        # Second detection should not re-signal
        signals = evaluator.detect_idle_sessions(current_time: Time.now)
        expect(signals).to be_empty
      end
    end

    describe '#end_session' do
      it 'generates session end summary' do
        start_time = Time.now - 600 # 10 minutes ago
        evaluator.record_page_landing(session_id: session_id, page_path: '/home', timestamp: start_time)
        5.times { |i| evaluator.record_interaction(session_id: session_id, interaction_type: 'click', target: "btn_#{i}", timestamp: start_time + 60) }

        signal = evaluator.end_session(session_id: session_id, timestamp: Time.now)

        expect(signal).to be_present
        expect(signal.activity_type).to eq(UserActivity::Signals::ActivityType::SessionEnd)
        expect(signal.metadata['interaction_count']).to eq(5)
        expect(signal.metadata['page_views']).to eq(1)
      end

      it 'removes session from tracking' do
        evaluator.record_page_landing(session_id: session_id, page_path: '/page')
        evaluator.end_session(session_id: session_id)

        expect(evaluator.session_metrics(session_id: session_id)).to be_nil
      end

      it 'returns nil for unknown session' do
        signal = evaluator.end_session(session_id: 'unknown_session')
        expect(signal).to be_nil
      end
    end

    describe '#session_metrics' do
      it 'returns current session metrics' do
        evaluator.record_page_landing(session_id: session_id, page_path: '/page')

        metrics = evaluator.session_metrics(session_id: session_id)

        expect(metrics).to be_present
        expect(metrics.session_id).to eq(session_id)
      end

      it 'returns nil for unknown session' do
        metrics = evaluator.session_metrics(session_id: 'unknown')
        expect(metrics).to be_nil
      end
    end
  end
end
