# A2UI Rails

A Ruby port of [Google's A2UI](https://github.com/google/A2UI) (Agent-to-User Interface) for Rails, using Turbo Streams and DSPy.rb for LLM-driven UI generation.

> **Status**: Early development. APIs will change.

## What is A2UI?

A2UI lets AI agents generate rich, interactive UIs by shipping **data and UI descriptions together** as structured output, rather than executable code. The client maintains a catalog of trusted components that the agent references by type.

This port maps A2UI concepts to Rails + Turbo:

| A2UI | Rails + Turbo |
|------|---------------|
| Surface | `<turbo-frame>` |
| `surfaceUpdate` | `<turbo-stream>` |
| `dataModelUpdate` | Stimulus controller values |
| Component catalog | ViewComponent library |
| JSON adjacency list | Rendered HTML fragments |

## Installation

Add to your Gemfile:

```ruby
gem 'dspy', '~> 0.34'
gem 'sorbet-runtime'

# Choose your LLM provider:
gem 'dspy-openai'    # OpenAI, OpenRouter, Ollama
# gem 'dspy-anthropic' # Claude
# gem 'dspy-gemini'    # Gemini
```

Copy the `lib/a2ui/` and `app/` directories to your Rails app.

Configure DSPy in an initializer:

```ruby
# config/initializers/dspy.rb
DSPy.configure do |c|
  c.lm = DSPy::LM.new('openai/gpt-4o-mini', api_key: ENV['OPENAI_API_KEY'])
end
```

Add the inflection for proper constant loading:

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'A2UI'
end
```

## Quick Start

### Generate UI from Natural Language

```ruby
manager = A2UI::SurfaceManager.new

# Create a surface from a natural language request
surface = manager.create(
  surface_id: 'booking-form',
  request: 'Create a booking form with guest count, date picker, and submit button',
  data: '{"booking": {"guests": 2}}'
)

# Render in your view
render partial: 'a2ui/surface', locals: { surface: surface }
```

### Handle User Actions

```ruby
action = A2UI::UserAction.new(
  name: 'submit_booking',
  surface_id: 'booking-form',
  source_id: 'submit-btn',
  context: { 'guests' => '3', 'date' => '2025-01-15' }
)

result = manager.handle_action(
  action: action,
  business_rules: 'Maximum 10 guests per booking'
)

# result.response_type => A2UI::ActionResponseType::UpdateUI
# result.streams => [A2UI::StreamOp, ...]
# result.components => [A2UI::Component, ...]
```

### Update Existing UI

```ruby
result = manager.update(
  surface_id: 'booking-form',
  request: 'Add a phone number field after the email'
)

# Returns Turbo Stream operations to apply
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Rails App                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DSPy Signatures          DSPy Modules         Controllers   │
│  ┌─────────────┐         ┌─────────────┐      ┌───────────┐ │
│  │ GenerateUI  │────────▶│ UIGenerator │─────▶│ Surfaces  │ │
│  │ UpdateUI    │         │ UIUpdater   │      │ Actions   │ │
│  │ HandleAction│         │ ActionHndlr │      └───────────┘ │
│  └─────────────┘         └─────────────┘            │       │
│         │                       │                   │       │
│         ▼                       ▼                   ▼       │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              A2UI::Components::Renderer                 ││
│  │         Maps Component structs → ViewComponents         ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                 Turbo Streams / Frames                  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Core Concepts

### Signatures (DSPy)

Type-safe interfaces for LLM calls using Sorbet types:

```ruby
class A2UI::GenerateUI < DSPy::Signature
  description 'Generate UI components from natural language.'

  input do
    const :request, String
    const :surface_id, String
    const :available_data, String, default: '{}'
  end

  output do
    const :root_id, String
    const :components, T::Array[Component]  # Union type
    const :initial_data, T::Array[DataUpdate], default: []
  end
end
```

### Union Types

Components and values use discriminated unions for type safety:

```ruby
# Value is either literal or a path reference
A2UI::Value = T.any(A2UI::LiteralValue, A2UI::PathReference)

# Children are either explicit IDs or data-driven
A2UI::Children = T.any(A2UI::ExplicitChildren, A2UI::DataDrivenChildren)

# Component is a union of all component types
A2UI::Component = T.any(
  A2UI::TextComponent,
  A2UI::ButtonComponent,
  A2UI::TextFieldComponent,
  A2UI::RowComponent,
  A2UI::ColumnComponent,
  # ... 13 total
)
```

DSPy automatically handles `_type` discrimination in LLM responses.

### Components

Each component type maps to a ViewComponent:

| Struct | ViewComponent | Purpose |
|--------|---------------|---------|
| `TextComponent` | `A2UI::Components::Text` | Display text with semantic hints |
| `ButtonComponent` | `A2UI::Components::Button` | Trigger actions |
| `TextFieldComponent` | `A2UI::Components::TextField` | Text input with data binding |
| `RowComponent` | `A2UI::Components::Row` | Horizontal flex layout |
| `ColumnComponent` | `A2UI::Components::Column` | Vertical flex layout |
| `CardComponent` | `A2UI::Components::Card` | Container with elevation |
| `CheckBoxComponent` | `A2UI::Components::CheckBox` | Boolean input |
| `DividerComponent` | `A2UI::Components::Divider` | Visual separator |

### Data Binding

Form inputs bind to the data model via JSON Pointer paths:

```ruby
# Component definition
A2UI::TextFieldComponent.new(
  id: 'guest-count',
  value: A2UI::PathReference.new(path: '/booking/guests'),
  input_type: A2UI::InputType::Number
)

# Renders with Stimulus binding
# <input data-controller="a2ui-binding"
#        data-a2ui-binding-path-value="/booking/guests" ...>
```

### Actions

Buttons dispatch actions with context from the data model:

```ruby
A2UI::ButtonComponent.new(
  id: 'submit',
  label: A2UI::LiteralValue.new(value: 'Book Now'),
  action: A2UI::Action.new(
    name: 'submit_booking',
    context: [
      A2UI::ContextBinding.new(key: 'booking', path: '/booking')
    ]
  )
)
```

## Stimulus Controllers

Three controllers handle client-side behavior:

- **`a2ui-data`** - Manages surface data model (JSON Pointer get/set)
- **`a2ui-binding`** - Two-way binding between inputs and data model
- **`a2ui-action`** - Dispatches user actions to server via fetch

## Routes

```ruby
namespace :a2ui do
  resources :surfaces, only: [:create, :show, :update, :destroy]
  resources :actions, only: [:create]
end
```

## Testing

```bash
bundle exec rspec spec/a2ui/types_spec.rb  # Unit tests (no API)
bundle exec rspec spec/a2ui/               # All tests (needs API key + VCR)
```

Integration tests use VCR to record LLM responses:

```ruby
RSpec.describe A2UI::GenerateUI, :vcr do
  it 'generates a booking form' do
    generator = A2UI::UIGenerator.new
    result = generator.call(
      request: 'Create a booking form',
      surface_id: 'booking'
    )

    expect(result.components).not_to be_empty
  end
end
```

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Type check (optional)
bundle exec srb tc
```

## Roadmap

- [ ] More components (Select, Slider, Tabs, Modal)
- [ ] Data-driven children (repeat templates from array)
- [ ] Optimizers for prompt tuning
- [ ] Rails generator for scaffolding
- [ ] JavaScript package for standalone use

## License

MIT

## See Also

- [Google A2UI](https://github.com/google/A2UI) - Original specification
- [DSPy.rb](https://github.com/vicentereig/dspy.rb) - Ruby DSPy framework
- [Hotwired Turbo](https://github.com/hotwired/turbo) - Turbo Streams/Frames
