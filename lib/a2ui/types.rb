# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

# Enums
require_relative 'types/text_usage_hint'
require_relative 'types/image_fit'
require_relative 'types/input_type'
require_relative 'types/distribution'
require_relative 'types/alignment'
require_relative 'types/orientation'
require_relative 'types/stream_action'
require_relative 'types/action_response_type'
require_relative 'types/screen_size'
require_relative 'types/modal_size'
require_relative 'types/ui_decision_type'
require_relative 'types/ui_decision_evidence'

# Value types
require_relative 'types/literal_value'
require_relative 'types/path_reference'

# Children types
require_relative 'types/explicit_children'
require_relative 'types/data_driven_children'

# Data value types
require_relative 'types/string_value'
require_relative 'types/number_value'
require_relative 'types/boolean_value'
require_relative 'types/object_value'

# Action types
require_relative 'types/context_binding'
require_relative 'types/action'
require_relative 'types/user_action'
require_relative 'types/validation_issue'

module A2UI
  # =============================================================================
  # TYPE ALIASES (Union Types)
  # Must be defined after all constituent types are loaded
  # =============================================================================

  # Value is either a literal string OR a path to the data model
  Value = T.type_alias { T.any(LiteralValue, PathReference) }

  # Children are either an explicit ID list OR data-driven from a path
  Children = T.type_alias { T.any(ExplicitChildren, DataDrivenChildren) }

  # Data model values can be string, number, boolean, or nested object
  DataValue = T.type_alias { T.any(StringValue, NumberValue, BooleanValue, ObjectValue) }
end

# Components (depend on type aliases above)
require_relative 'types/text_component'
require_relative 'types/image_component'
require_relative 'types/icon_component'
require_relative 'types/button_component'
require_relative 'types/text_field_component'
require_relative 'types/check_box_component'
require_relative 'types/slider_component'
require_relative 'types/select_component'
require_relative 'types/row_component'
require_relative 'types/column_component'
require_relative 'types/card_component'
require_relative 'types/list_component'
require_relative 'types/divider_component'
require_relative 'types/tab_item'
require_relative 'types/tabs_component'
require_relative 'types/modal_component'

# Editorial components (depend on Briefing types)
require_relative '../briefing'
require_relative 'types/editorial_headline_component'
require_relative 'types/editorial_insight_component'
require_relative 'types/editorial_metric_component'
require_relative 'types/editorial_metrics_row_component'
require_relative 'types/editorial_divider_component'
require_relative 'types/editorial_page_component'

module A2UI
  # Component union type - all possible component types
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
      DividerComponent,
      TabsComponent,
      ModalComponent,
      # Editorial components
      EditorialHeadlineComponent,
      EditorialInsightComponent,
      EditorialMetricComponent,
      EditorialMetricsRowComponent,
      EditorialDividerComponent,
      EditorialPageComponent
    )
  end
end

# Types that depend on Component/DataValue unions
require_relative 'types/data_update'
require_relative 'types/stream_op'
