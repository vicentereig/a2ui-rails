# typed: strict
# frozen_string_literal: true

module A2UI
  # Configuration options for A2UI
  class Configuration
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :default_model

    sig { returns(T.nilable(T.any(ActiveSupport::Cache::Store, Symbol))) }
    attr_accessor :cache_store

    sig { returns(T::Boolean) }
    attr_accessor :debug

    sig { returns(T.nilable(String)) }
    attr_accessor :component_prefix

    sig { void }
    def initialize
      @default_model = T.let('anthropic/claude-sonnet-4-20250514', T.nilable(String))
      @cache_store = T.let(nil, T.nilable(T.any(ActiveSupport::Cache::Store, Symbol)))
      @debug = T.let(false, T::Boolean)
      @component_prefix = T.let('a2ui', T.nilable(String))
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def configuration
      @configuration ||= T.let(Configuration.new, T.nilable(Configuration))
      T.must(@configuration)
    end

    sig { params(block: T.proc.params(config: Configuration).void).void }
    def configure(&block)
      block.call(configuration)
    end

    sig { void }
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
