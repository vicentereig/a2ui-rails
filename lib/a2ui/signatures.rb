# typed: strict
# frozen_string_literal: true

require 'dspy'
require 'sorbet-runtime'

module A2UI
  # =============================================================================
  # ENUMS
  # =============================================================================

  class TextUsageHint < T::Enum
    enums do
      H1 = new('h1')
      H2 = new('h2')
      H3 = new('h3')
      H4 = new('h4')
      H5 = new('h5')
      Body = new('body')
      Caption = new('caption')
    end
  end

  class ImageFit < T::Enum
    enums do
      Contain = new('contain')
      Cover = new('cover')
      Fill = new('fill')
      ScaleDown = new('scale_down')
      None = new('none')
    end
  end

  class InputType < T::Enum
    enums do
      Text = new('text')
      Number = new('number')
      Date = new('date')
      Longtext = new('longtext')
      Email = new('email')
      Tel = new('tel')
      Url = new('url')
    end
  end

  class Distribution < T::Enum
    enums do
      Start = new('start')
      Center = new('center')
      End = new('end')
      SpaceBetween = new('space_between')
      SpaceAround = new('space_around')
      SpaceEvenly = new('space_evenly')
    end
  end

  class Alignment < T::Enum
    enums do
      Start = new('start')
      Center = new('center')
      End = new('end')
      Stretch = new('stretch')
    end
  end

  class Orientation < T::Enum
    enums do
      Horizontal = new('horizontal')
      Vertical = new('vertical')
    end
  end

  class StreamAction < T::Enum
    enums do
      Append = new('append')
      Prepend = new('prepend')
      Replace = new('replace')
      Update = new('update')
      Remove = new('remove')
      Before = new('before')
      After = new('after')
    end
  end

  class ActionResponseType < T::Enum
    enums do
      UpdateUI = new('update_ui')
      Navigate = new('navigate')
      DeleteSurface = new('delete_surface')
      NoOp = new('no_op')
    end
  end

  class ScreenSize < T::Enum
    enums do
      Mobile = new('mobile')
      Tablet = new('tablet')
      Desktop = new('desktop')
    end
  end

  # =============================================================================
  # VALUE REFERENCES - Union Types
  # A value is either a literal string OR a path to the data model
  # =============================================================================

  class LiteralValue < T::Struct
    const :value, String, description: 'The literal string value'
  end

  class PathReference < T::Struct
    const :path, String, description: 'JSON Pointer to data model (e.g., /user/name)'
  end

  # DSPy discriminates via _type field automatically
  Value = T.type_alias { T.any(LiteralValue, PathReference) }

  # =============================================================================
  # CHILDREN REFERENCES - Union Types
  # Children are either an explicit ID list OR data-driven from a path
  # =============================================================================

  class ExplicitChildren < T::Struct
    const :ids, T::Array[String], description: 'List of child component IDs'
  end

  class DataDrivenChildren < T::Struct
    const :path, String, description: 'JSON Pointer to array in data model'
    const :template_id, String, description: 'Component ID to use as template for each item'
  end

  Children = T.type_alias { T.any(ExplicitChildren, DataDrivenChildren) }

  # =============================================================================
  # DATA VALUES - Union Types
  # Data model values can be string, number, boolean, or nested object
  # =============================================================================

  class StringValue < T::Struct
    const :key, String
    const :string, String
  end

  class NumberValue < T::Struct
    const :key, String
    const :number, Float
  end

  class BooleanValue < T::Struct
    const :key, String
    const :boolean, T::Boolean
  end

  class ObjectValue < T::Struct
    const :key, String
    const :entries, T::Hash[String, T.untyped], default: {}, description: 'Nested key-value pairs as JSON-like hash'
  end

  DataValue = T.type_alias { T.any(StringValue, NumberValue, BooleanValue, ObjectValue) }

  # =============================================================================
  # ACTION DEFINITION
  # =============================================================================

  class ContextBinding < T::Struct
    const :key, String, description: 'Key name in the action context'
    const :path, String, description: 'JSON Pointer to extract value from'
  end

  class Action < T::Struct
    const :name, String, description: 'Action identifier sent to server'
    const :context, T::Array[ContextBinding], default: []
  end

  # =============================================================================
  # COMPONENTS - Using Union for Polymorphism
  # Each component type is a separate struct; DSPy handles _type discrimination
  # =============================================================================

  class TextComponent < T::Struct
    const :id, String
    const :content, Value, description: 'Text content'
    const :usage_hint, TextUsageHint, default: TextUsageHint::Body
  end

  class ImageComponent < T::Struct
    const :id, String
    const :src, Value, description: 'Image URL'
    const :alt, String, default: ''
    const :fit, ImageFit, default: ImageFit::Contain
  end

  class IconComponent < T::Struct
    const :id, String
    const :name, String, description: 'Material icon name (e.g., check, close, menu)'
    const :size, Integer, default: 24
  end

  class ButtonComponent < T::Struct
    const :id, String
    const :label, Value, description: 'Button label text'
    const :action, Action
    const :disabled, T::Boolean, default: false
    const :variant, String, default: 'primary', description: 'primary, secondary, or danger'
  end

  class TextFieldComponent < T::Struct
    const :id, String
    const :value, PathReference, description: 'Path to bound value in data model'
    const :input_type, InputType, default: InputType::Text
    const :label, String, default: ''
    const :placeholder, String, default: ''
    const :is_required, T::Boolean, default: false, description: 'Whether the field is required'
  end

  class CheckBoxComponent < T::Struct
    const :id, String
    const :checked, PathReference, description: 'Path to boolean in data model'
    const :label, String, default: ''
  end

  class SliderComponent < T::Struct
    const :id, String
    const :value, PathReference, description: 'Path to numeric value'
    const :min, Float, default: 0.0
    const :max, Float, default: 100.0
    const :step, Float, default: 1.0
    const :label, String, default: ''
  end

  class SelectComponent < T::Struct
    const :id, String
    const :value, PathReference, description: 'Path to selected value'
    const :options_path, PathReference, description: 'Path to array of {value, label} options'
    const :label, String, default: ''
    const :placeholder, String, default: 'Select...'
  end

  class RowComponent < T::Struct
    const :id, String
    const :children, Children
    const :distribution, Distribution, default: Distribution::Start
    const :alignment, Alignment, default: Alignment::Center
    const :gap, Integer, default: 8
  end

  class ColumnComponent < T::Struct
    const :id, String
    const :children, Children
    const :distribution, Distribution, default: Distribution::Start
    const :alignment, Alignment, default: Alignment::Stretch
    const :gap, Integer, default: 8
  end

  class CardComponent < T::Struct
    const :id, String
    const :child_id, String, description: 'ID of the child component'
    const :title, String, default: ''
    const :elevation, Integer, default: 1
  end

  class ListComponent < T::Struct
    const :id, String
    const :children, Children
    const :orientation, Orientation, default: Orientation::Vertical
  end

  class DividerComponent < T::Struct
    const :id, String
    const :orientation, Orientation, default: Orientation::Horizontal
  end

  # The union of all components - DSPy adds _type discriminator
  Component = T.type_alias do
    T.any(
      TextComponent,
      ImageComponent,
      IconComponent,
      ButtonComponent,
      TextFieldComponent,
      CheckBoxComponent,
      SliderComponent,
      SelectComponent,
      RowComponent,
      ColumnComponent,
      CardComponent,
      ListComponent,
      DividerComponent
    )
  end

  # =============================================================================
  # DATA MODEL UPDATE
  # =============================================================================

  class DataUpdate < T::Struct
    const :path, String, description: 'JSON Pointer path (e.g., /reservation/guests)'
    const :entries, T::Array[DataValue], description: 'Values to set at this path'
  end

  # =============================================================================
  # TURBO STREAM OPERATION
  # =============================================================================

  class StreamOp < T::Struct
    const :action, StreamAction
    const :target, String, description: 'Target element ID'
    const :component_ids, T::Array[String], default: [], description: 'Components to render'
  end

  # =============================================================================
  # SIGNATURE: GENERATE UI
  # =============================================================================

  class GenerateUI < DSPy::Signature
    description 'Generate UI components from natural language.'

    input do
      const :request, String, description: 'What UI to create'
      const :surface_id, String
      const :available_data, String, default: '{}', description: 'Available data model as JSON'
    end

    output do
      const :root_id, String, description: 'Root component ID'
      const :components, T::Array[Component], description: 'Component adjacency list'
      const :initial_data, T::Array[DataUpdate], default: [], description: 'Initial data values'
    end
  end

  # =============================================================================
  # SIGNATURE: UPDATE UI
  # =============================================================================

  class UpdateUI < DSPy::Signature
    description 'Generate incremental Turbo Stream updates.'

    input do
      const :request, String, description: 'What to update'
      const :surface_id, String
      const :current_components, T::Array[Component], default: []
      const :current_data, String, default: '{}', description: 'Current data as JSON'
    end

    output do
      const :streams, T::Array[StreamOp], description: 'Turbo Stream operations'
      const :components, T::Array[Component], default: [], description: 'New/updated components'
      const :data_updates, T::Array[DataUpdate], default: []
    end
  end

  # =============================================================================
  # SIGNATURE: HANDLE ACTION
  # =============================================================================

  class UserAction < T::Struct
    const :name, String, description: 'Action name from component'
    const :surface_id, String
    const :source_id, String, description: 'Component ID that triggered action'
    const :context, T::Hash[String, String], default: {}, description: 'Resolved context values'
  end

  class HandleAction < DSPy::Signature
    description 'Process user action and generate response.'

    input do
      const :action, UserAction
      const :current_data, String, default: '{}', description: 'Surface data as JSON'
      const :business_rules, String, default: '', description: 'Domain constraints'
    end

    output do
      const :response_type, ActionResponseType
      const :streams, T::Array[StreamOp], default: []
      const :components, T::Array[Component], default: []
      const :data_updates, T::Array[DataUpdate], default: []
      const :redirect_url, String, default: '', description: 'URL if navigating'
      const :message, String, default: '', description: 'User-facing message'
    end
  end

  # =============================================================================
  # SIGNATURE: VALIDATE DATA
  # =============================================================================

  class ValidationIssue < T::Struct
    const :path, String, description: 'JSON Pointer to invalid field'
    const :message, String
    const :code, String, description: 'Machine-readable code like required, invalid_format'
  end

  class ValidateData < DSPy::Signature
    description 'Validate data model against rules.'

    input do
      const :data, String, description: 'Data model as JSON'
      const :rules, String, description: 'Validation rules'
    end

    output do
      const :valid, T::Boolean
      const :issues, T::Array[ValidationIssue], default: []
    end
  end

  # =============================================================================
  # SIGNATURE: PARSE NATURAL INPUT
  # =============================================================================

  class ParseInput < DSPy::Signature
    description 'Convert natural language to data updates.'

    input do
      const :text, String, description: 'User natural language input'
      const :target_path, String, description: 'Path to update'
      const :expected_schema, String, default: '', description: 'Expected structure hint'
    end

    output do
      const :updates, T::Array[DataUpdate]
      const :confidence, Float, description: '0.0-1.0 confidence score'
      const :needs_clarification, T::Boolean
      const :question, String, default: '', description: 'Clarification question if needed'
    end
  end

  # =============================================================================
  # SIGNATURE: ADAPT LAYOUT
  # =============================================================================

  class AdaptLayout < DSPy::Signature
    description 'Adapt components for screen size.'

    input do
      const :components, T::Array[Component]
      const :root_id, String
      const :screen, ScreenSize
    end

    output do
      const :components, T::Array[Component], description: 'Adapted components'
      const :hidden_ids, T::Array[String], default: [], description: 'IDs to hide'
    end
  end
end
