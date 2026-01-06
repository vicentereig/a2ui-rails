# typed: strict
# frozen_string_literal: true

module A2UI
  # Type alias for action context types: action_name => context struct class
  ActionSchemas = T.type_alias { T::Hash[Symbol, T.class_of(T::Struct)] }

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

    # Maps action names to their expected context struct types
    sig { returns(ActionSchemas) }
    attr_reader :action_schemas

    sig { params(id: String, action_schemas: ActionSchemas).void }
    def initialize(id, action_schemas: {})
      @id = id
      @root_id = T.let(nil, T.nilable(String))
      @components = T.let({}, T::Hash[String, Component])
      @data = T.let({}, T::Hash[String, T.untyped])
      @action_schemas = T.let(action_schemas, ActionSchemas)
    end

    # Returns JSON schemas for all registered actions (for client-side validation)
    sig { returns(T::Hash[Symbol, T::Hash[Symbol, T.untyped]]) }
    def action_json_schemas
      @action_schemas.transform_values do |struct_class|
        DSPy::TypeSystem::SorbetJsonSchema.generate_struct_schema(struct_class)
      end
    end

    # Coerces raw context hash to the registered struct type for an action
    sig { params(action_name: String, raw_context: T::Hash[String, T.untyped]).returns(T::Struct) }
    def coerce_context(action_name, raw_context)
      struct_class = @action_schemas[action_name.to_sym]
      raise ArgumentError, "Unknown action: #{action_name}" unless struct_class

      A2UI::TypeCoercion.coerce(raw_context, struct_class)
    end

    sig { params(root_id: String, components: T::Array[Component]).void }
    def set_components(root_id, components)
      @root_id = root_id
      components.each { |c| @components[c.id] = c }
    end

    sig { params(updates: T::Array[DataUpdate]).void }
    def apply_data_updates(updates)
      updates.each do |update|
        value = entries_to_hash(update.entries)
        set_path(update.path, value)
      end
    end

    sig { params(path: String).returns(T.untyped) }
    def get_data(path)
      resolve_path(path, @data)
    end

    sig { returns(String) }
    def to_json
      @data.to_json
    end

    private

    sig { params(path: String, value: T.untyped).void }
    def set_path(path, value)
      if path.nil? || path == '' || path == '/'
        @data = value.is_a?(Hash) ? value : { 'value' => value }
        return
      end

      parts = path.split('/').reject(&:empty?)
      current = @data

      parts[0...-1].each do |part|
        current[part] = {} unless current[part].is_a?(Hash)
        current = current[part]
      end

      current[parts.last] = value
    end

    sig { params(path: String, obj: T.untyped).returns(T.untyped) }
    def resolve_path(path, obj)
      return obj if path.nil? || path == '' || path == '/'

      parts = path.split('/').reject(&:empty?)
      parts.reduce(obj) { |current, part| current.is_a?(Hash) ? current[part] : nil }
    end

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
