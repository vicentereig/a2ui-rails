# typed: strict
# frozen_string_literal: true

module A2UI
  class Surface
    extend T::Sig

    sig { returns(String) }
    attr_reader :id

    sig { returns(T.nilable(String)) }
    attr_reader :root_id

    sig { returns(T::Hash[String, Component]) }
    attr_reader :components

    sig { returns(T::Hash[String, T.untyped]) }
    attr_reader :data

    sig { params(id: String).void }
    def initialize(id)
      @id = id
      @root_id = T.let(nil, T.nilable(String))
      @components = T.let({}, T::Hash[String, Component])
      @data = T.let({}, T::Hash[String, T.untyped])
    end

    sig { params(root_id: String, components: T::Array[Component]).void }
    def set_components(root_id, components)
      @root_id = root_id
      components.each { |c| @components[c.id] = c }
    end

    sig { params(updates: T::Array[DataUpdate]).void }
    def apply_data_updates(updates)
      updates.each do |update|
        @data[update.path] = entries_to_hash(update.entries)
      end
    end

    sig { params(path: String).returns(T.untyped) }
    def get_data(path)
      @data[path]
    end

    sig { returns(String) }
    def to_json
      @data.to_json
    end

    private

    sig { params(entries: T::Array[DataValue]).returns(T::Hash[String, T.untyped]) }
    def entries_to_hash(entries)
      entries.to_h do |entry|
        value = case entry
                when StringValue then entry.string
                when NumberValue then entry.number
                when BooleanValue then entry.boolean
                when ObjectValue then entry.entries # Already a hash
                end
        [entry.key, value]
      end
    end
  end
end
