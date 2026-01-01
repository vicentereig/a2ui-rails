# typed: strict
# frozen_string_literal: true

module UserActivity
  # Signal types for user activity patterns
  module Signals
    extend T::Sig

    # Type of user activity event
    class ActivityType < T::Enum
      enums do
        PageLanding = new('page_landing')
        SessionStart = new('session_start')
        SessionEnd = new('session_end')
        Interaction = new('interaction')
        IdlePeriod = new('idle_period')
        EngagementPeak = new('engagement_peak')
        NotificationResponse = new('notification_response')
      end
    end

    # Priority level for activity signals
    class SignalPriority < T::Enum
      enums do
        Low = new('low')
        Medium = new('medium')
        High = new('high')
      end
    end

    # Engagement level classification
    class EngagementLevel < T::Enum
      enums do
        Idle = new('idle')
        Passive = new('passive')
        Active = new('active')
        HighlyEngaged = new('highly_engaged')
      end
    end

    # A signal representing a meaningful user activity event
    class ActivitySignal < T::Struct
      const :id, String, description: 'Unique signal identifier'
      const :activity_type, ActivityType, description: 'Type of activity'
      const :priority, SignalPriority, description: 'Signal priority'
      const :title, String, description: 'Short title for the signal'
      const :summary, String, description: 'Brief description of the activity'
      const :timestamp, Time, description: 'When the activity occurred'
      const :session_id, T.nilable(String), description: 'Associated session ID'
      const :metadata, T::Hash[String, T.untyped], default: {}
    end

    # Tracks session-level metrics
    class SessionMetrics < T::Struct
      const :session_id, String
      const :started_at, Time
      const :last_interaction_at, Time
      const :interaction_count, Integer, default: 0
      const :page_views, Integer, default: 0
      const :scroll_depth_max, Float, default: 0.0
      const :engagement_level, EngagementLevel, default: EngagementLevel::Idle
    end

    # Evaluates user activity patterns and generates signals
    class ActivityEvaluator
      extend T::Sig

      # Idle threshold in seconds (2 minutes)
      IDLE_THRESHOLD = 120

      # Engagement thresholds
      PASSIVE_THRESHOLD = 3    # interactions
      ACTIVE_THRESHOLD = 8     # interactions
      HIGHLY_ENGAGED_THRESHOLD = 15

      sig { void }
      def initialize
        @sessions = T.let({}, T::Hash[String, SessionMetrics])
      end

      # Record a page landing and evaluate if signal-worthy
      sig { params(session_id: String, page_path: String, timestamp: Time).returns(T::Array[ActivitySignal]) }
      def record_page_landing(session_id:, page_path:, timestamp: Time.now)
        signals = []

        # Check if new session
        unless @sessions.key?(session_id)
          @sessions[session_id] = SessionMetrics.new(
            session_id: session_id,
            started_at: timestamp,
            last_interaction_at: timestamp
          )

          signals << ActivitySignal.new(
            id: "session_start_#{session_id}",
            activity_type: ActivityType::SessionStart,
            priority: SignalPriority::Medium,
            title: 'New Session',
            summary: "User started a new session on #{page_path}.",
            timestamp: timestamp,
            session_id: session_id,
            metadata: { 'page_path' => page_path }
          )
        end

        session = @sessions[session_id]
        return signals unless session

        # Update session metrics
        @sessions[session_id] = SessionMetrics.new(
          session_id: session_id,
          started_at: session.started_at,
          last_interaction_at: timestamp,
          interaction_count: session.interaction_count,
          page_views: session.page_views + 1,
          scroll_depth_max: session.scroll_depth_max,
          engagement_level: session.engagement_level
        )

        signals << ActivitySignal.new(
          id: "page_landing_#{session_id}_#{timestamp.to_i}",
          activity_type: ActivityType::PageLanding,
          priority: SignalPriority::Low,
          title: 'Page View',
          summary: "User visited #{page_path}.",
          timestamp: timestamp,
          session_id: session_id,
          metadata: { 'page_path' => page_path, 'page_views' => session.page_views + 1 }
        )

        signals
      end

      # Record a user interaction (click, scroll, form input)
      sig { params(session_id: String, interaction_type: String, target: String, timestamp: Time).returns(T::Array[ActivitySignal]) }
      def record_interaction(session_id:, interaction_type:, target:, timestamp: Time.now)
        signals = []

        session = @sessions[session_id]
        return signals unless session

        new_count = session.interaction_count + 1
        time_since_last = timestamp - session.last_interaction_at

        # Check for idle period recovery
        if time_since_last > IDLE_THRESHOLD
          signals << ActivitySignal.new(
            id: "idle_recovery_#{session_id}_#{timestamp.to_i}",
            activity_type: ActivityType::Interaction,
            priority: SignalPriority::Medium,
            title: 'User Returned',
            summary: "User returned after #{format_duration(time_since_last)} of inactivity.",
            timestamp: timestamp,
            session_id: session_id,
            metadata: { 'idle_duration_seconds' => time_since_last.to_i }
          )
        end

        # Update engagement level
        new_engagement = calculate_engagement_level(new_count)
        previous_engagement = session.engagement_level

        # Check for engagement level change
        if engagement_level_increased?(previous_engagement, new_engagement)
          signals << ActivitySignal.new(
            id: "engagement_peak_#{session_id}_#{timestamp.to_i}",
            activity_type: ActivityType::EngagementPeak,
            priority: SignalPriority::High,
            title: "Engagement: #{new_engagement.serialize}",
            summary: "User engagement increased to #{new_engagement.serialize} level.",
            timestamp: timestamp,
            session_id: session_id,
            metadata: {
              'previous_level' => previous_engagement.serialize,
              'new_level' => new_engagement.serialize,
              'interaction_count' => new_count
            }
          )
        end

        # Update session
        @sessions[session_id] = SessionMetrics.new(
          session_id: session_id,
          started_at: session.started_at,
          last_interaction_at: timestamp,
          interaction_count: new_count,
          page_views: session.page_views,
          scroll_depth_max: session.scroll_depth_max,
          engagement_level: new_engagement
        )

        signals
      end

      # Record scroll depth
      sig { params(session_id: String, depth: Float, timestamp: Time).returns(T::Array[ActivitySignal]) }
      def record_scroll_depth(session_id:, depth:, timestamp: Time.now)
        signals = []

        session = @sessions[session_id]
        return signals unless session

        # Only signal if new max depth reached
        return signals unless depth > session.scroll_depth_max

        # Update session
        @sessions[session_id] = SessionMetrics.new(
          session_id: session_id,
          started_at: session.started_at,
          last_interaction_at: timestamp,
          interaction_count: session.interaction_count,
          page_views: session.page_views,
          scroll_depth_max: depth,
          engagement_level: session.engagement_level
        )

        # Signal at notable depth milestones
        milestones = [0.25, 0.5, 0.75, 1.0]
        crossed_milestone = milestones.find { |m| depth >= m && session.scroll_depth_max < m }

        if crossed_milestone
          signals << ActivitySignal.new(
            id: "scroll_milestone_#{session_id}_#{(crossed_milestone * 100).to_i}",
            activity_type: ActivityType::Interaction,
            priority: SignalPriority::Low,
            title: "Scroll: #{(crossed_milestone * 100).to_i}%",
            summary: "User scrolled to #{(crossed_milestone * 100).to_i}% of page content.",
            timestamp: timestamp,
            session_id: session_id,
            metadata: { 'depth' => depth, 'milestone' => crossed_milestone }
          )
        end

        signals
      end

      # Check for idle users and generate signals
      sig { params(current_time: Time).returns(T::Array[ActivitySignal]) }
      def detect_idle_sessions(current_time: Time.now)
        signals = []

        @sessions.each do |session_id, session|
          idle_duration = current_time - session.last_interaction_at

          next unless idle_duration > IDLE_THRESHOLD

          # Only signal if user was previously active
          next if session.engagement_level == EngagementLevel::Idle

          signals << ActivitySignal.new(
            id: "idle_#{session_id}_#{current_time.to_i}",
            activity_type: ActivityType::IdlePeriod,
            priority: SignalPriority::Medium,
            title: 'User Idle',
            summary: "User has been idle for #{format_duration(idle_duration)}.",
            timestamp: current_time,
            session_id: session_id,
            metadata: {
              'idle_duration_seconds' => idle_duration.to_i,
              'last_engagement_level' => session.engagement_level.serialize
            }
          )

          # Update engagement level to idle
          @sessions[session_id] = SessionMetrics.new(
            session_id: session_id,
            started_at: session.started_at,
            last_interaction_at: session.last_interaction_at,
            interaction_count: session.interaction_count,
            page_views: session.page_views,
            scroll_depth_max: session.scroll_depth_max,
            engagement_level: EngagementLevel::Idle
          )
        end

        signals
      end

      # End a session and generate summary signal
      sig { params(session_id: String, timestamp: Time).returns(T.nilable(ActivitySignal)) }
      def end_session(session_id:, timestamp: Time.now)
        session = @sessions.delete(session_id)
        return nil unless session

        duration = timestamp - session.started_at

        ActivitySignal.new(
          id: "session_end_#{session_id}",
          activity_type: ActivityType::SessionEnd,
          priority: SignalPriority::Medium,
          title: 'Session Ended',
          summary: "Session lasted #{format_duration(duration)} with #{session.interaction_count} interactions.",
          timestamp: timestamp,
          session_id: session_id,
          metadata: {
            'duration_seconds' => duration.to_i,
            'interaction_count' => session.interaction_count,
            'page_views' => session.page_views,
            'max_scroll_depth' => session.scroll_depth_max,
            'peak_engagement' => session.engagement_level.serialize
          }
        )
      end

      # Get current session metrics
      sig { params(session_id: String).returns(T.nilable(SessionMetrics)) }
      def session_metrics(session_id:)
        @sessions[session_id]
      end

      private

      sig { params(interaction_count: Integer).returns(EngagementLevel) }
      def calculate_engagement_level(interaction_count)
        if interaction_count >= HIGHLY_ENGAGED_THRESHOLD
          EngagementLevel::HighlyEngaged
        elsif interaction_count >= ACTIVE_THRESHOLD
          EngagementLevel::Active
        elsif interaction_count >= PASSIVE_THRESHOLD
          EngagementLevel::Passive
        else
          EngagementLevel::Idle
        end
      end

      sig { params(previous: EngagementLevel, current: EngagementLevel).returns(T::Boolean) }
      def engagement_level_increased?(previous, current)
        levels = [EngagementLevel::Idle, EngagementLevel::Passive, EngagementLevel::Active, EngagementLevel::HighlyEngaged]
        levels.index(current).to_i > levels.index(previous).to_i
      end

      sig { params(seconds: Numeric).returns(String) }
      def format_duration(seconds)
        if seconds < 60
          "#{seconds.to_i}s"
        elsif seconds < 3600
          minutes = (seconds / 60).to_i
          "#{minutes}m"
        else
          hours = (seconds / 3600).to_i
          minutes = ((seconds % 3600) / 60).to_i
          "#{hours}h #{minutes}m"
        end
      end
    end
  end
end
