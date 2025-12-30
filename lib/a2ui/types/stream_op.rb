# typed: strict
# frozen_string_literal: true

module A2UI
  class StreamOp < T::Struct
    const :action, StreamAction
    const :target, String, description: 'Target element ID'
    const :component_ids, T::Array[String], default: [], description: 'Components to render'
  end
end
